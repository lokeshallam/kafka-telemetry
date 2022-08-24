package com.mycompany.kafka.producer;

import org.apache.avro.Schema;
import org.apache.avro.generic.GenericRecord;
import org.apache.avro.generic.GenericRecordBuilder;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.*;

import static java.lang.String.format;

public class GenericRecordProducer {

    private static final Logger log = LoggerFactory.getLogger(GenericRecordProducer.class);
    private static final String TOPIC = "topic";
    private static final String SCHEMA = "schema";
    private static final String MESSAGES = "messages";
    private static final String BATCH_SIZE = "batch.size";
    private static final String FREQUENCY_MS = "frequency.ms";

    private final KafkaProducer<Long, GenericRecord> producer;
    private final String topicName;
    private final long messages;
    private final String schemaName;
    private final int batchSize;
    private final long frequencyMs;

    public GenericRecordProducer(KafkaProducer<Long, GenericRecord> producer, Properties appProperties) {
        this.producer = producer;
        topicName = appProperties.getProperty(TOPIC);
        messages = Long.parseLong(appProperties.getProperty(MESSAGES));
        schemaName = appProperties.getProperty(SCHEMA);
        batchSize = Integer.parseInt(appProperties.getProperty(BATCH_SIZE));
        frequencyMs = Long.parseLong(appProperties.getProperty(FREQUENCY_MS));
    }

    public void start() throws IOException {

        SchemaLoader schemaLoader = new SchemaLoader();
        Schema schema = schemaLoader.getSchema(schemaName);
        if (schema == null) {
            throw new RuntimeException(format("Schema \"%s.avsc\" was not found in the classpath", schemaName));
        }
        DataGenerator dataGenerator = new DataGenerator(new HashMap<>());

        log.info("Producer started");
        long count = 0;
        try {
            while (count < messages) {
                long currentBatch = count + batchSize < messages ? batchSize : messages - count;
                List<GenericRecord> records = convert(schema, dataGenerator.generate(schema, (int) currentBatch));
                for (GenericRecord record : records) {
                    producer.send(new ProducerRecord<>(topicName, (Long) record.get("id"), record));
                }
                producer.flush();
                log.info("Produced {} messages", batchSize);
                count += batchSize;
                try {
                    Thread.sleep(frequencyMs);
                } catch (InterruptedException ignored) {}
            }
        } catch (Exception e) {
            log.error("Error producing messages", e);
            throw e;
        } finally {
            producer.close();
        }
        log.info("Produced total of {} messages", count);
        log.info("Producer finished");
    }

    private List<GenericRecord> convert(Schema schema, List<Map<String, Object>> values) {

        List<GenericRecord> records = new ArrayList<>();
        for (Map<String, Object> value : values) {
            GenericRecordBuilder recordBuilder = new GenericRecordBuilder(schema);
            for (Schema.Field field : schema.getFields()) {
                recordBuilder.set(field, value.get(field.name()));
            }
            records.add(recordBuilder.build());
        }
        return records;
    }
}
