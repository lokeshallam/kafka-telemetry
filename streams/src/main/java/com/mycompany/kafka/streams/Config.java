package com.mycompany.kafka.streams;

import com.mycompany.kafka.streams.common.StreamsLifecycle;
import com.mycompany.kafka.streams.common.SerdeCreator;

import io.confluent.kafka.schemaregistry.client.CachedSchemaRegistryClient;
import io.confluent.kafka.schemaregistry.client.SchemaRegistryClient;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.streams.Topology;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.HashMap;
import java.util.Map;
import java.util.Properties;

@Configuration
public class Config {

    private static final String SCHEMA_REGISTRY_URL = "schema.registry.url";
    private static final String SCHEMA_CACHE_CAPACITY = "schema.cache.capacity";
    private static final String STREAM_TYPE = "stream.type";
    private static final String STATELESS = "stateless";

    @Bean
    @ConfigurationProperties(prefix = "kafka.streams")
    public Properties streamsProperties() {
        return new Properties();
    }

    @Bean
    @ConfigurationProperties(prefix = "kafka.producer")
    public Properties producerProperties() {
        return new Properties();
    }

    @Bean(name = "applicationProperties")
    @ConfigurationProperties(prefix = "application")
    public Properties applicationProperties() {
        return new Properties();
    }

    @Bean
    public SchemaRegistryClient schemaRegistryClient() {

        Properties kafkaProperties = streamsProperties();

        // pull out schema registry properties from kafka properties to pass to schema registry client
        Map<String, Object> schemaProperties = new HashMap<>();
        for (Map.Entry<Object, Object> entry : kafkaProperties.entrySet()) {
            String propertyName = (String) entry.getKey();
            if (propertyName.startsWith("schema.registry.") || propertyName.startsWith("basic.auth.")) {
                schemaProperties.put(propertyName, entry.getValue());
            }
        }
        return new CachedSchemaRegistryClient(kafkaProperties.getProperty(SCHEMA_REGISTRY_URL),
                Integer.parseInt(kafkaProperties.getProperty(SCHEMA_CACHE_CAPACITY)), schemaProperties);
    }

    @Bean
    public SerdeCreator serdeCreator() {
        return new SerdeCreator(streamsProperties(), schemaRegistryClient());
    }

    @Bean
    public StatelessTopologyBuilder statelessTopologyBuilder() {
        return new StatelessTopologyBuilder(applicationProperties(), serdeCreator(), new KafkaProducer<>(producerProperties()), schemaRegistryClient());
    }

    @Bean
    public StatefulTopologyBuilder statefulTopologyBuilder() {
        return new StatefulTopologyBuilder(applicationProperties(), serdeCreator(), new KafkaProducer<>(producerProperties()), schemaRegistryClient());
    }

    @Bean
    public StreamsLifecycle streamsLifecycle(ApplicationContext applicationContext) {

        Properties applicationProperties = applicationProperties();
        Topology topology;
        if (applicationProperties.get(STREAM_TYPE).equals(STATELESS)) {
            topology = statelessTopologyBuilder().build(applicationProperties);
        } else {
            topology = statefulTopologyBuilder().build(applicationProperties);
        }
        return new StreamsLifecycle(topology, applicationProperties, streamsProperties(), applicationContext);
    }
}
