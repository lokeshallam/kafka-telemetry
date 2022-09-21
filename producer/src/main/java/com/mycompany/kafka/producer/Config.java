package com.mycompany.kafka.producer;

import io.confluent.kafka.serializers.AbstractKafkaSchemaSerDeConfig;
import org.apache.avro.generic.GenericRecord;
import org.apache.kafka.clients.admin.AdminClient;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.Properties;

@Configuration
public class Config {

    private static final String SCHEMA_REGISTRY_AUTH = "schema.registry.auth";

    @Bean
    @ConfigurationProperties(prefix = "producer")
    public Properties producerProperties() {
        return new Properties();
    }

    @Bean
    @ConfigurationProperties(prefix = "admin")
    public Properties adminProperties() {
        return new Properties();
    }

    @Bean
    @ConfigurationProperties(prefix = "application")
    public Properties applicationProperties() {
        return new Properties();
    }

    @Bean
    public KafkaProducer<Long, GenericRecord> kafkaProducer() {
        return new KafkaProducer<>(prepare(producerProperties()));
    }

    @Bean
    public AdminClient adminClient() {
        return AdminClient.create(prepare(adminProperties()));
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
