package com.mycompany.kafka.consumer;

import org.apache.avro.generic.GenericRecord;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.util.Properties;

@SpringBootApplication
public class Application implements CommandLineRunner {

    @Autowired
    private KafkaConsumer<Long, GenericRecord> kafkaConsumer;
    @Autowired
    private Properties applicationProperties;

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args).close();
    }

    @Override
    public void run(String... args) {
        Consumer consumer = new Consumer(kafkaConsumer, applicationProperties);
        consumer.start();
    }
}
