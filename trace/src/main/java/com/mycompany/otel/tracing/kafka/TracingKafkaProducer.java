/*
 * Copyright 2017-2020 The OpenTracing Authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 */
package com.mycompany.otel.tracing.kafka;

import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.SpanContext;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.context.Scope;
import io.opentracing.propagation.Format;
import io.opentracing.tag.Tags;
import org.apache.kafka.clients.consumer.ConsumerGroupMetadata;
import org.apache.kafka.clients.consumer.OffsetAndMetadata;
import org.apache.kafka.clients.producer.Callback;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.producer.RecordMetadata;
import org.apache.kafka.common.Metric;
import org.apache.kafka.common.MetricName;
import org.apache.kafka.common.PartitionInfo;
import org.apache.kafka.common.TopicPartition;
import org.apache.kafka.common.errors.ProducerFencedException;
import org.apache.kafka.common.header.Headers;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Duration;
import java.util.*;
import java.util.concurrent.Future;
import java.util.function.BiFunction;

import static io.opentracing.contrib.kafka.SpanDecorator.STANDARD_TAGS;

public class TracingKafkaProducer<K, V> implements Producer<K, V> {

    private static final Logger log = LoggerFactory.getLogger(TracingKafkaProducer.class);

    private Producer<K, V> producer;
    private final Tracer tracer;
    private final BiFunction<String, ProducerRecord, String> producerSpanNameProvider;
    private Collection<SpanDecorator> spanDecorators;

    TracingKafkaProducer(Producer<K, V> producer, Tracer tracer,
                         Collection<SpanDecorator> spanDecorators,
                         BiFunction<String, ProducerRecord, String> producerSpanNameProvider) {
        this.producer = producer;
        this.tracer = tracer;
        this.spanDecorators = Collections.unmodifiableCollection(spanDecorators);
        this.producerSpanNameProvider = (producerSpanNameProvider == null)
                ? ClientSpanNameProvider.PRODUCER_OPERATION_NAME
                : producerSpanNameProvider;
    }

    public TracingKafkaProducer(Producer<K, V> producer, Tracer tracer) {
        this.producer = producer;
        this.tracer = tracer;
        this.spanDecorators = Collections.singletonList(STANDARD_TAGS);
        this.producerSpanNameProvider = ClientSpanNameProvider.PRODUCER_OPERATION_NAME;
    }

    public TracingKafkaProducer(Producer<K, V> producer, Tracer tracer,
                                BiFunction<String, ProducerRecord, String> producerSpanNameProvider) {
        this.producer = producer;
        this.tracer = tracer;
        this.spanDecorators = Collections.singletonList(STANDARD_TAGS);
        this.producerSpanNameProvider = (producerSpanNameProvider == null)
                ? ClientSpanNameProvider.PRODUCER_OPERATION_NAME
                : producerSpanNameProvider;
    }

    @Override
    public void initTransactions() {
        producer.initTransactions();
    }

    @Override
    public void beginTransaction() throws ProducerFencedException {
        producer.beginTransaction();
    }

    @Override
    public void sendOffsetsToTransaction(Map<TopicPartition, OffsetAndMetadata> offsets,
                                         String consumerGroupId)
            throws ProducerFencedException {
        producer.sendOffsetsToTransaction(offsets, consumerGroupId);
    }

    @Override
    public void sendOffsetsToTransaction(Map<TopicPartition, OffsetAndMetadata> offsets,
                                         ConsumerGroupMetadata groupMetadata) throws ProducerFencedException {
        producer.sendOffsetsToTransaction(offsets, groupMetadata);
    }

    @Override
    public void commitTransaction() throws ProducerFencedException {
        producer.commitTransaction();
    }

    @Override
    public void abortTransaction() throws ProducerFencedException {
        producer.abortTransaction();
    }

    @Override
    public Future<RecordMetadata> send(ProducerRecord<K, V> record) {
        return send(record, null, null);
    }

    public Future<RecordMetadata> send(ProducerRecord<K, V> record, SpanContext parent) {
        return send(record, null, parent);
    }

    @Override
    public Future<RecordMetadata> send(ProducerRecord<K, V> record, Callback callback) {
        return send(record, callback, null);
    }

    public Future<RecordMetadata> send(ProducerRecord<K, V> record,
                                       Callback callback,
                                       SpanContext parent) {

        Span span = buildAndInjectSpan(record, tracer, producerSpanNameProvider, parent, spanDecorators);
        try (Scope ignored = tracer.activateSpan(span)) {
            Callback wrappedCallback = new TracingCallback(callback, span, tracer, spanDecorators);
            return producer.send(record, wrappedCallback);
        }
    }

    @Override
    public void flush() {
        producer.flush();
    }

    @Override
    public List<PartitionInfo> partitionsFor(String topic) {
        return producer.partitionsFor(topic);
    }

    @Override
    public Map<MetricName, ? extends Metric> metrics() {
        return producer.metrics();
    }

    @Override
    public void close() {
        producer.close();
    }

    @Override
    public void close(Duration duration) {
        producer.close(duration);
    }

    public <K, V> Span buildAndInjectSpan(ProducerRecord<K, V> record,
                                          Tracer tracer,
                                          BiFunction<String, ProducerRecord, String> producerSpanNameProvider,
                                          SpanContext parent,
                                          Collection<SpanDecorator> spanDecorators) {
        String producerOper = "To_" + record.topic();
        Tracer.SpanBuilder spanBuilder = tracer.buildSpan(producerSpanNameProvider.apply(producerOper, record)).withTag(Tags.SPAN_KIND.getKey(), "producer");
        SpanContext spanContext = extractSpanContext(record.headers(), tracer);
        if (spanContext != null) {
            spanBuilder.asChildOf(spanContext);
        } else if (parent != null) {
            spanBuilder.asChildOf(parent);
        }

        Span span = spanBuilder.start();
        Iterator var9 = spanDecorators.iterator();

        while(var9.hasNext()) {
            SpanDecorator decorator = (SpanDecorator)var9.next();
            decorator.onSend(record, span);
        }

        try {
            inject(span.context(), record.headers(), tracer);
        } catch (Exception var11) {
            log.error("failed to inject span context. sending record second time?", var11);
        }

        return span;
    }

    private SpanContext extractSpanContext(Headers headers, Tracer tracer) {
        return tracer.extract(Format.Builtin.TEXT_MAP, new HeadersMapExtractAdapter(headers));
    }

    private void inject(SpanContext spanContext, Headers headers, Tracer tracer) {
        tracer.inject(spanContext, Format.Builtin.TEXT_MAP, new HeadersMapInjectAdapter(headers));
    }
}
