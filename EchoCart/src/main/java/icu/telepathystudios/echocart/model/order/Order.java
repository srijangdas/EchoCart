package icu.telepathystudios.echocart.model.order;

import icu.telepathystudios.echocart.util.Jackson3JsonbConverter;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import tools.jackson.databind.node.ObjectNode;

import java.util.Date;
import java.util.UUID;

@Entity
@Table(name="orders")
@Getter
@Setter
public class Order {
    @Id
    @GeneratedValue(strategy= GenerationType.UUID)
    private UUID id;

    private UUID customerId;
    private UUID partnerId;

    @Enumerated(EnumType.STRING)
    private OrderStatus orderStatus;

    @JdbcTypeCode(SqlTypes.JSON)
    @Convert(converter = Jackson3JsonbConverter.class)
    @Column(columnDefinition = "jsonb")
    private ObjectNode orderJson;

    private double EstimatedPrice;

    private Date createdAt;
    private Date updatedAt;
}
