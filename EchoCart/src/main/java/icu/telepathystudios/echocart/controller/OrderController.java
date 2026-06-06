package icu.telepathystudios.echocart.controller;

import icu.telepathystudios.echocart.dto.order.CreateOrderRequest;
import icu.telepathystudios.echocart.dto.order.OrderResponse;
import icu.telepathystudios.echocart.service.OrderService;
import lombok.AllArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/orders")
@CrossOrigin("*")
@AllArgsConstructor
public class OrderController {
    private final OrderService orderService;

    @PostMapping("/")
    public OrderResponse createOrder(@RequestBody CreateOrderRequest request){
        return orderService.createOrder(request);
    }
    @GetMapping("/customer")
    public List<OrderResponse> getCustomerOrders(
    ){
        return orderService.getCustomerOrders();
    }

    @GetMapping("/available")
    public List<OrderResponse> getAvailableOrders(){
        return orderService.getAvailableOrders();
    }

    @PostMapping("/{orderId}/accept")
    public OrderResponse acceptOrder(
            @PathVariable UUID orderId,
            @RequestParam UUID partnerId
    ){
        return orderService.acceptOrder(orderId, partnerId);
    }

    @PostMapping("/{orderId}/pickup")
    public OrderResponse pickupOrder(
            @PathVariable UUID orderId
    ){
        return orderService.pickupOrder(orderId);
    }

    @PostMapping("/{orderId}/deliver")
    public OrderResponse deliverOrder(
            @PathVariable UUID orderId
    ){
        return orderService.deliverOrder(orderId);
    }

}
