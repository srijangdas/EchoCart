package icu.telepathystudios.echocart.dto.order;

import icu.telepathystudios.echocart.model.order.OrderStatus;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;
import tools.jackson.databind.node.ObjectNode;

import java.util.UUID;

@Getter
@Setter
@AllArgsConstructor
public class OrderResponse {
    private UUID orderId;

    private OrderStatus orderStatus;

    private ObjectNode orderJson;

    private Double estimatedPrice;
}
