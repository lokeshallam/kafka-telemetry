package com.mycompany.otel.tracing.kafka;

import io.opentelemetry.api.References;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.SpanContext;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.api.trace.Format;
import io.opentelemetry.api.trace.
import java.util.Collection;
import java.util.Collections;
import java.util.function.BiFunction;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.header.Headers;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class TracingKafkaUtils {

    private static final Logger logger = LoggerFactory.getLogger(TracingKafkaUtils.class);
    public static final String TO_PREFIX = "To_";
    public static final String FROM_PREFIX = "From_";

    /**
     * Extract Span Context from record headers
     *
     * @param headers record headers
     * @return span context
     */
    public static SpanContext extractSpanContext(Headers headers, Tracer tracer) {
        return tracer
                .extract(Format.Builtin.TEXT_MAP, new HeadersMapExtractAdapter(headers));
    }

    /**
     * Inject Span Context to record headers
     *
     * @param spanContext Span Context
     * @param headers     record headers
     */
    public static void inject(SpanContext spanContext, Headers headers,
                              Tracer tracer) {
        tracer.inject(spanContext, Format.Builtin.TEXT_MAP, new HeadersMapInjectAdapter(headers));
    }

    public static <K, V> Span buildAndInjectSpan(ProducerRecord<K, V> record, Tracer tracer) {
        return buildAndInjectSpan(record, tracer, ClientSpanNameProvider.PRODUCER_OPERATION_NAME, null,
                Collections.singletonList(SpanDecorator.STANDARD_TAGS));
    }

    public static <K, V> Span buildAndInjectSpan(ProducerRecord<K, V> record, Tracer tracer,
                                                 BiFunction<String, ProducerRecord, String> producerSpanNameProvider,
                                                 SpanContext parent) {
        return buildAndInjectSpan(record, tracer, producerSpanNameProvider, parent,
                Collections.singletonList(SpanDecorator.STANDARD_TAGS));
    }

    public static <K, V> Span buildAndInjectSpan(ProducerRecord<K, V> record, Tracer tracer,
                                                 BiFunction<String, ProducerRecord, String> producerSpanNameProvider,
                                                 SpanContext parent, Collection<SpanDecorator> spanDecorators) {
        String producerOper =
                TO_PREFIX + record.topic(); // <======== It provides better readability in the UI
        Tracer.SpanBuilder spanBuilder = tracer
                .buildSpan(producerSpanNameProvider.apply(producerOper, record))
                .withTag(Tags.SPAN_KIND.getKey(), Tags.SPAN_KIND_PRODUCER);

        SpanContext spanContext = TracingKafkaUtils.extractSpanContext(record.headers(), tracer);

        if (spanContext != null) {
            spanBuilder.asChildOf(spanContext);
        } else if (parent != null) {
            spanBuilder.asChildOf(parent);
        }

        Span span = spanBuilder.start();

        for (SpanDecorator decorator : spanDecorators) {
            decorator.onSend(record, span);
        }

        try {
            TracingKafkaUtils.inject(span.context(), record.headers(), tracer);
        } catch (Exception e) {
            // it can happen if headers are read only (when record is sent second time)
            logger.error("failed to inject span context. sending record second time?", e);
        }

        return span;
    }

    public static <K, V> void buildAndFinishChildSpan(ConsumerRecord<K, V> record, Tracer tracer) {
        buildAndFinishChildSpan(record, tracer, ClientSpanNameProvider.CONSUMER_OPERATION_NAME,
                Collections.singletonList(SpanDecorator.STANDARD_TAGS));
    }

    public static <K, V> void buildAndFinishChildSpan(ConsumerRecord<K, V> record, Tracer tracer,
                                                      BiFunction<String, ConsumerRecord, String> consumerSpanNameProvider) {
        buildAndFinishChildSpan(record, tracer, consumerSpanNameProvider,
                Collections.singletonList(SpanDecorator.STANDARD_TAGS));
    }

    public static <K, V> void buildAndFinishChildSpan(ConsumerRecord<K, V> record, Tracer tracer,
                                                      BiFunction<String, ConsumerRecord, String> consumerSpanNameProvider,
                                                      Collection<SpanDecorator> spanDecorators) {
        SpanContext parentContext = TracingKafkaUtils.extractSpanContext(record.headers(), tracer);
        String consumerOper =
                FROM_PREFIX + record.topic(); // <====== It provides better readability in the UI
        Tracer.SpanBuilder spanBuilder = tracer
                .buildSpan(consumerSpanNameProvider.apply(consumerOper, record))
                .withTag(Tags.SPAN_KIND.getKey(), Tags.SPAN_KIND_CONSUMER);

        if (parentContext != null) {
            spanBuilder.addReference(References.FOLLOWS_FROM, parentContext);
        }

        Span span = spanBuilder.start();

        for (SpanDecorator decorator : spanDecorators) {
            decorator.onResponse(record, span);
        }

        span.finish();

        // Inject created span context into record headers for extraction by client to continue span chain
        inject(span.context(), record.headers(), tracer);
    }
}