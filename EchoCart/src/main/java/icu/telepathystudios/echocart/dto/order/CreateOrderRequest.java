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
          "items": [
            {
              "id": 1,
              "name": "Potato",
              "weight": "2kg",
              "status": "PENDING"
            }
          ],
          "deliveryAddress": "Salt Lake, Kolkata",
          "specialInstructions": "Fresh vegetables only",
          "source": "voice"
        },
        "estimatedPrice": 69.99
        }
        """
)
public class CreateOrderRequest {
    private ObjectNode orderJson;
    private double estimatedPrice;
}
