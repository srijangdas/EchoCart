package icu.telepathystudios.echocart.service;

import com.fasterxml.jackson.databind.JsonNode;
import icu.telepathystudios.echocart.dto.order.CreateOrderRequest;
import icu.telepathystudios.echocart.dto.order.OrderResponse;
import icu.telepathystudios.echocart.model.User;
import icu.telepathystudios.echocart.model.order.Order;
import icu.telepathystudios.echocart.model.order.OrderStatus;
import icu.telepathystudios.echocart.repo.OrderRepo;
import icu.telepathystudios.echocart.repo.UserRepo;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class OrderService {
    private final OrderRepo orderRepo;
    private final UserRepo userRepo;

    public OrderResponse createOrder(CreateOrderRequest request) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();

        UUID customerId = getCustomerId(auth);

        Order order = new Order();
        order.setCustomerId(customerId);
        order.setOrderStatus(OrderStatus.PENDING);
        order.setOrderJson(request.getOrderJson());
        order.setEstimatedPrice(request.getEstimatedPrice());

        order.setCreatedAt(new Date());
        order.setUpdatedAt(new Date());

        orderRepo.save(order);

        return mapToResponse(order);
    }

    public List<OrderResponse> getCustomerOrders() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();

        UUID customerId = getCustomerId(auth);

        return orderRepo.findByCustomerId(customerId)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    public List<OrderResponse> getAvailableOrders() {
        return orderRepo.findByOrderStatus(OrderStatus.PENDING)
                .stream()
                .filter(order -> order.getPartnerId() == null)
                .map(this::mapToResponse)
                .toList();
    }

    public OrderResponse acceptOrder(UUID orderId, UUID partnerId) {
        Order order = orderRepo.findById(orderId)
                .orElseThrow(() ->
                        new RuntimeException("Order not found"));

        if(order.getPartnerId() != null){
            throw new RuntimeException(
                    "Order already accepted");
        }

        order.setPartnerId(partnerId);
        order.setOrderStatus(OrderStatus.ACCEPTED);
        order.setUpdatedAt(new Date());

        orderRepo.save(order);

        return mapToResponse(order);
    }

    public OrderResponse pickupOrder(UUID orderId) {
        Order order = orderRepo.findById(orderId)
                .orElseThrow(() ->
                        new RuntimeException("Order not found"));

        order.setOrderStatus(OrderStatus.IN_TRANSIT);
        order.setUpdatedAt(new Date());

        orderRepo.save(order);

        return mapToResponse(order);
    }

    public OrderResponse deliverOrder(UUID orderId) {
        Order order = orderRepo.findById(orderId)
                .orElseThrow(() ->
                        new RuntimeException("Order not found"));

        order.setOrderStatus(OrderStatus.DELIVERED);
        order.setUpdatedAt(new Date());

        orderRepo.save(order);

        return mapToResponse(order);
    }

    private OrderResponse mapToResponse(Order order) {
        return new OrderResponse(
                order.getId(),
                order.getOrderStatus(),
                order.getOrderJson(),
                order.getEstimatedPrice());
    }

    private UUID getCustomerId(Authentication auth) {

        if(auth == null) {
            throw new RuntimeException("Authentication object is null, relogin");
        }
        String phoneNo = auth.getName();

        User user = userRepo.findByPhoneNo(phoneNo).orElseThrow(
                ()->
                        new RuntimeException("User not found")
        );
        if(!user.getRole().equals("USER")){
            throw new RuntimeException("Customers Allowed Only!");
        }

        return user.getId();
    }
}
