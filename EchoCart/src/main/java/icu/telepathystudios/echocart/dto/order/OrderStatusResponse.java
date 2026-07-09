package icu.telepathystudios.echocart.dto.order;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
public class OrderStatusResponse {
    private String status;
    private String deliveryPhoneNo;
}
