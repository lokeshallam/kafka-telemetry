package com.mycompany.kafka.streams.common;

import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.ReactiveHealthIndicator;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.List;

@Component
public class StreamsHealthCheck implements ReactiveHealthIndicator {

    private final List<StreamsLifecycle> streams;

    public StreamsHealthCheck(List<StreamsLifecycle> streams) {
        this.streams = streams;
    }

    @Override
    public Mono<Health> health() {
        return Flux.fromIterable(streams)
                .all(StreamsLifecycle::isHealthy)
                .map(isHealthy -> {
                    if (isHealthy) {
                        return Health.up().build();
                    }
                    return Health.down().build();
                });
    }
}
