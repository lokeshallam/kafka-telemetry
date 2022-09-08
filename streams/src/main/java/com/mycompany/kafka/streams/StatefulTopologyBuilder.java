package com.mycompany.kafka.streams;

import com.mycompany.kafka.streams.common.SerdeCreator;

import io.confluent.kafka.schemaregistry.client.SchemaRegistryClient;
import org.apache.avro.generic.GenericRecord;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.common.header.Header;
import org.apache.kafka.common.header.Headers;
import org.apache.kafka.common.serialization.Serde;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.common.utils.Bytes;
import org.apache.kafka.streams.KeyValue;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.Topology;
import org.apache.kafka.streams.kstream.*;
import org.apache.kafka.streams.processor.ProcessorContext;
import org.apache.kafka.streams.state.KeyValueBytesStoreSupplier;
import org.apache.kafka.streams.state.KeyValueStore;
import org.apache.kafka.streams.state.StoreBuilder;
import org.apache.kafka.streams.state.Stores;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;

import java.util.*;

public class StatefulTopologyBuilder {

    private static final Logger log = LoggerFactory.getLogger(StatefulTopologyBuilder.class);

    private final String inputTopic;
    private final String outputTopic;
    private final String failureOutputTopic;
    private final boolean inMemoryStateStores;
    private final SerdeCreator serdes;
    private final KafkaProducer<Long, GenericRecord> errorHandler;
    private final SchemaRegistryClient schemaRegistryClient;

    public StatefulTopologyBuilder(Properties applicationProperties,
                                   SerdeCreator serdes,
                                   KafkaProducer<Long, GenericRecord> errorHandler,
                                   SchemaRegistryClient schemaRegistryClient) {
        this.serdes = serdes;
        this.inputTopic = applicationProperties.getProperty("input.topic");
        this.outputTopic = applicationProperties.getProperty("output.topic");
        this.failureOutputTopic = applicationProperties.getProperty("failure.output.topic");
        this.inMemoryStateStores = Boolean.parseBoolean(applicationProperties.getProperty("in.memory.state.stores"));
        this.errorHandler = errorHandler;
        this.schemaRegistryClient = schemaRegistryClient;
    }

    public Topology build(Properties streamProperties) {

        // uncomment to get output schema by latest version
        //String subject = outputTopic + "-value";
        //final Schema outputTopicSchema = new Schema.Parser().parse(this.schemaRegistryClient.getLatestSchemaMetadata(subject).getSchema());
        // get output schema by ID
        //final Schema outputTopicSchema = new Schema.Parser().parse(this.schemaRegistryClient.getSchemaById(outputTopicSchemaId).canonicalString());

        log.info("Subscribing to input topic {}", inputTopic);
        final StreamsBuilder builder = new StreamsBuilder();
        builder.stream(inputTopic, Consumed.with(Serdes.Long(), serdes.createGenericSerde(false)))
                .transformValues(new StatefulTransformerSupplier("consumer"))
                .map((k, v) -> {
                    return new KeyValue<>(k, v);
                })
                .toTable(getStateStore("store", Serdes.Long(), serdes.createGenericSerde(false)))
                .toStream()
                .transformValues(new StatefulTransformerSupplier("producer"))
                .to(outputTopic, Produced.with(Serdes.Long(), serdes.createGenericSerde(false)));

        return builder.build(streamProperties);
    }

    private Materialized<Long, GenericRecord, KeyValueStore<Bytes, byte[]>> getStateStore(String storeName,
                                                                                          Serde<Long> keySerde,
                                                                                          Serde<GenericRecord> valueSerde) {
        KeyValueBytesStoreSupplier supplier = inMemoryStateStores ? Stores.inMemoryKeyValueStore(storeName) :
                Stores.persistentKeyValueStore(storeName);
        return Materialized .<Long, GenericRecord>as(supplier).withKeySerde(keySerde).withValueSerde(valueSerde);
    }

    private static class StatefulTransformerSupplier implements ValueTransformerWithKeySupplier<Long, GenericRecord, GenericRecord> {

        private String tag;

        public StatefulTransformerSupplier(String tag) {
            this.tag = tag;
        }

        @Override
        public ValueTransformerWithKey<Long, GenericRecord, GenericRecord> get() {
            return new StatefulTransformer(tag);
        }

        @Override
        public Set<StoreBuilder<?>> stores() {
            return ValueTransformerWithKeySupplier.super.stores();
        }
    }

    private static class StatefulTransformer implements ValueTransformerWithKey<Long, GenericRecord, GenericRecord> {

        private ProcessorContext processorContext;
        private String tag;

        public StatefulTransformer(String tag) {
            this.tag = tag;
        }

        @Override
        public void init(ProcessorContext processorContext) {
            this.processorContext = processorContext;
        }

        @Override
        public GenericRecord transform(Long key, GenericRecord value) {
            Headers headers = processorContext.headers();
            log.info( tag + " headers:");
            for (Header header : headers) {
                String headerValue = new String(header.value());
                String[] headerValues = headerValue.split("-");
                MDC.put("trace_id", headerValues[1]);
                MDC.put("span_id", headerValues[2]);
                MDC.put("trace_flags", headerValues[3]);
                log.info(header.key() + "=" + headerValue);
            }
            return value;
        }

        @Override
        public void close() {
        }
    }
}
