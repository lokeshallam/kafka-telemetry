package com.mycompany.kafka.producer;

import org.apache.avro.Schema;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.*;

public class SchemaLoader {

    private static final Logger log = LoggerFactory.getLogger(SchemaLoader.class);
    private static final String SCHEMAS_PATH = "/**/*.avsc";

    private final Map<String, Schema> schemas = new HashMap<>();

    public SchemaLoader() throws IOException {
        loadSchemas();
    }

    public Schema getSchema(String name) {
        return schemas.get(name);
    }

    private void loadSchemas() throws IOException {

        PathMatchingResourcePatternResolver resolver = new PathMatchingResourcePatternResolver();
        Resource[] resources = resolver.getResources(SCHEMAS_PATH);

        // sort resources by filename so that dependencies can be enforced by the
        // order of the schema files alphabetically
        List<Resource> sortedResources = Arrays.asList(resources);
        sortedResources.sort(Comparator.comparing(o -> Objects.requireNonNull(o.getFilename())));

        for (Resource resource : sortedResources) {
            try (InputStream in = resource.getInputStream();
                 BufferedReader br = new BufferedReader(new InputStreamReader(in))) {

                StringBuilder sb = new StringBuilder();
                String line;
                while ((line = br.readLine()) != null) {
                    sb.append(line.trim());
                }

                log.info("Loading schema from file {}", resource.getFilename());
                Schema schema = new Schema.Parser().parse(sb.toString());
                log.info("Schema {} loaded", schema.getName().toLowerCase());
                schemas.put(schema.getName().toLowerCase(), schema);
            }
        }
    }
}
