package icu.telepathystudios.echocart.dto.order;

import lombok.Getter;
import lombok.Setter;
import tools.jackson.databind.node.ObjectNode;

@Getter
@Setter
public class CreateOrderRequest {
    private ObjectNode orderJson;
    private double estimatedPrice;
}
