package com.mycompany.kafka.producer;

import org.apache.avro.generic.GenericRecord;
import org.apache.kafka.clients.admin.AdminClient;
import org.apache.kafka.clients.admin.NewTopic;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.common.errors.TopicExistsException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.util.Collections;
import java.util.Optional;
import java.util.Properties;
import java.util.concurrent.ExecutionException;

@SpringBootApplication
public class Application implements CommandLineRunner {

    private static final String TOPIC = "topic";
    private static final String PARTITIONS = "partitions";

    @Autowired
    private KafkaProducer<Long, GenericRecord> kafkaProducer;
    @Autowired
    private AdminClient adminClient;
    @Autowired
    private Properties appProperties;

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args).close();
    }

    @Override
    public void run(String... args) throws Exception {

        String topicName = appProperties.getProperty(TOPIC);
        int partitions = Integer.parseInt(appProperties.getProperty(PARTITIONS));
        createTopic(topicName, partitions);

        GenericRecordProducer genericRecordProducer = new GenericRecordProducer(kafkaProducer, appProperties);
        genericRecordProducer.start();
    }

    private void createTopic(String topicName, int partitions) {

        final NewTopic newTopic = new NewTopic(topicName, Optional.of(partitions), Optional.empty());
        try {
            adminClient.createTopics(Collections.singletonList(newTopic)).all().get();
        } catch (final InterruptedException | ExecutionException e) {
            // Ignore if TopicExistsException, which may be valid if topic exists
            if (!(e.getCause() instanceof TopicExistsException)) {
                throw new RuntimeException(e);
            }
        }
    }
}
