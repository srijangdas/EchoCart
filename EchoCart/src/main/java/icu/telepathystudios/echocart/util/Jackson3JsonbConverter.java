package icu.telepathystudios.echocart.util;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.node.ObjectNode;

@Converter(autoApply = false)
public class Jackson3JsonbConverter implements AttributeConverter<ObjectNode, String> {

    private static final ObjectMapper mapper = new ObjectMapper();

    @Override
    public String convertToDatabaseColumn(ObjectNode attribute) {
        try {
            return attribute == null ? null : mapper.writeValueAsString(attribute);
        } catch (Exception e) {
            throw new IllegalArgumentException("Error converting ObjectNode to JSON string", e);
        }
    }

    @Override
    public ObjectNode convertToEntityAttribute(String dbData) {
        try {
            return dbData == null ? null : (ObjectNode) mapper.readTree(dbData);
        } catch (Exception e) {
            throw new IllegalArgumentException("Error converting JSON string to ObjectNode", e);
        }
    }
}