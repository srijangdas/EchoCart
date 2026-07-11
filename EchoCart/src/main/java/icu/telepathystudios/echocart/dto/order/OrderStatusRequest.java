package icu.telepathystudios.echocart.dto.order;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@Setter
@Getter
@AllArgsConstructor
public class OrderStatusRequest {
    private String status;
}
