package com.mycompany.kafka.consumer;

import io.confluent.kafka.serializers.AbstractKafkaSchemaSerDeConfig;
import org.apache.avro.generic.GenericRecord;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.Properties;

@Configuration
public class Config {

    private static final String SCHEMA_REGISTRY_AUTH = "schema.registry.auth";

    @Bean
    @ConfigurationProperties(prefix = "consumer")
    public Properties kafkaProperties() {
        return new Properties();
    }

    @Bean
    @ConfigurationProperties(prefix = "application")
    public Properties applicationProperties() {
        return new Properties();
    }

    @Bean
    public KafkaConsumer<Long, GenericRecord> kafkaConsumer() {
        return new KafkaConsumer<>(prepare(kafkaProperties()));
    }

    private Properties prepare(Properties properties) {

        // if schema registry auth is not enabled then remove any properties having to do with it
        boolean auth = Boolean.parseBoolean(properties.getProperty(SCHEMA_REGISTRY_AUTH));
        if (!auth) {
            properties.remove(SCHEMA_REGISTRY_AUTH);
            properties.remove(AbstractKafkaSchemaSerDeConfig.BASIC_AUTH_CREDENTIALS_SOURCE);
            properties.remove(AbstractKafkaSchemaSerDeConfig.USER_INFO_CONFIG);
        }
        return properties;
    }
}