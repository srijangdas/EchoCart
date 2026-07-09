package icu.telepathystudios.echocart.dto.order;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;
import tools.jackson.databind.node.ObjectNode;

@Getter
@Setter
@Schema(
        type = "object",
        example = """
        {
                "orderJson": {
                            "itemList": [
                                {
                                    "name": "Mechanical Keyboard",
                                    "brand": "Logitech",
                                    "color": "Black",
                                    "price": 85.0,
                                    "quantity": 1
                                },
                                {
                                    "name": "Wireless Mouse",
                                    "brand": "Razer",
                                    "model": "DeathAdder",
                                    "price": 85.0,
                                    "quantity": 1
                                }
                            ]
                        },
                        "estimatedPrice": 170.0
        }
        """
)
public class CreateOrderRequest {
    private ObjectNode orderJson;
    private double estimatedPrice;
}
