package com.mycompany.kafka.producer;

import com.github.javafaker.Faker;
import org.apache.avro.Schema;
import org.apache.avro.generic.GenericData;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.nio.ByteBuffer;
import java.time.ZoneId;
import java.util.*;
import java.util.concurrent.TimeUnit;

import static java.lang.String.format;

public class DataGenerator {

    private final Faker faker;
    private final Map<String, String> fieldRegex;

    public DataGenerator(Map<String, String> fieldRegex) {
        this.faker = new Faker();
        this.fieldRegex = fieldRegex;
    }

    public List<Map<String, Object>> generate(Schema schema, int count) {
        List<Map<String, Object>> records = new ArrayList<>(count);
        for (int i = 0; i < count; i++) {
            Map<String, Object> record = generate(schema);
            records.add(record);
        }
        return records;
    }

    public Map<String, Object> generate(Schema schema) {

        String schemaName = schema.getName();
        Map<String, Object> record = new HashMap<>();

        for (Schema.Field f : schema.getFields()) {

            Schema fieldSchema = f.schema();
            // if field is type union then grab the first non-"null" type as field type
            if (fieldSchema.getType().getName().equals("union")) {
                Optional<Schema> unionType = fieldSchema.getTypes().stream()
                        .filter(t -> !t.getType().getName().equals("null")).findFirst();
                if (unionType.isEmpty()) {
                    throw new RuntimeException(format("field \"%s\" union type does not have a non-null type", f.name()));
                }
                fieldSchema = unionType.get();
            }
            // field is not a logical type
            if (fieldSchema.getLogicalType() != null) {
                switch (fieldSchema.getLogicalType().getName()) {
                    case "decimal":
                        int scale  = (Integer) fieldSchema.getObjectProps().get("scale");
                        int precision = (Integer) fieldSchema.getObjectProps().get("precision");
                        record.put(f.name(), createBigDecimal(scale, precision));
                        break;
                    case "timestamp-micros":
                    case "timestamp-millis":
                        record.put(f.name(), faker.date().past(365, TimeUnit.DAYS).toInstant());
                        break;
                    case "date":
                        record.put(f.name(), faker.date().past(365, TimeUnit.DAYS).toInstant()
                                .atZone(ZoneId.systemDefault()).toLocalDate());
                        break;
                    default:
                        throw new RuntimeException(format("Field \"%s\" logical type \"%s\" unknown", f.name(), fieldSchema.getLogicalType().getName()));
                }
            } else {
                switch (fieldSchema.getType().getName()) {
                    case "bytes":
                        record.put(f.name(), ByteBuffer.wrap(faker.letterify("??????").getBytes()));
                        break;
                    case "enum":
                        List<String> symbols = fieldSchema.getEnumSymbols();
                        int selected = faker.number().numberBetween(0, symbols.size() - 1);
                        record.put(f.name(), new GenericData.EnumSymbol(fieldSchema, symbols.get(selected)));
                        break;
                    // using "fixed" 16 byte array for UUIDs
                    case "fixed":
                        record.put(f.name(), new GenericData.Fixed(fieldSchema, toBytes(UUID.randomUUID())));
                        break;
                    case "int":
                        if (f.name().toUpperCase().contains("AGE")) {
                            record.put(f.name(), faker.number().numberBetween(1, 123));
                        } else if (f.name().toUpperCase().contains("YEAR")) {
                            record.put(f.name(), faker.number().numberBetween(1900, 2050));
                        } else {
                            record.put(f.name(), faker.number().numberBetween(1, Integer.MAX_VALUE));
                        }
                        break;
                    case "long":
                        record.put(f.name(), faker.number().numberBetween(1L, Long.MAX_VALUE));
                        break;
                    case "double":
                        record.put(f.name(), faker.number().randomDouble(2, 1L, Long.MAX_VALUE));
                        break;
                    case "float":
                        record.put(f.name(), (float) faker.number().randomDouble(4, 1, 1000));
                        break;
                    case "boolean":
                        record.put(f.name(), faker.bool().bool() ? 1 : 0);
                        break;
                    case "string":

                        // regex fields are keyed by schema name and field name
                        String regexFieldName = schemaName + "." + f.name();
                        // first check if field has a custom regex
                        if (fieldRegex.containsKey(regexFieldName)) {
                            record.put(f.name(), faker.regexify(fieldRegex.get(regexFieldName)));
                        } else if (f.name().toUpperCase().contains("ADDRESS")) {
                            record.put(f.name(), faker.address().fullAddress());
                        } else if (f.name().equalsIgnoreCase("FIRSTNAME")) {
                            record.put(f.name(), faker.name().firstName());
                        } else if (f.name().equalsIgnoreCase("LASTNAME")) {
                            record.put(f.name(), faker.name().lastName());
                        } else if (f.name().toUpperCase().contains("NAME")) {
                            record.put(f.name(), faker.name().fullName());
                        } else if (f.name().toUpperCase().contains("FLAG")) {
                            record.put(f.name(), faker.bool().bool() ? "Y" : "N");
                        } else {
                            record.put(f.name(), faker.letterify("??????????"));
                        }
                        break;
                    default:
                        throw new RuntimeException(format("Field \"%s\" type \"%s\" unknown", f.name(), fieldSchema.getType().getName()));
                }
            }
        }
        return record;
    }

    private byte[] toBytes(UUID uuid) {
        ByteBuffer bb = ByteBuffer.wrap(new byte[16]);
        bb.putLong(uuid.getMostSignificantBits());
        bb.putLong(uuid.getLeastSignificantBits());
        return bb.array();
    }

    private BigDecimal createBigDecimal(int scale, int precision) {

        //return new BigDecimal(BigInteger.valueOf(new Random().nextInt(100001)), 2);

        String format = "#".repeat(Math.max(0, precision - scale)) + "." + "#".repeat(Math.max(0, scale));
        return new BigDecimal(faker.numerify(format));
    }
}
