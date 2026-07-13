package icu.telepathystudios.echocart.service;

import icu.telepathystudios.echocart.dto.order.CreateOrderRequest;
import icu.telepathystudios.echocart.dto.order.OrderResponse;
import icu.telepathystudios.echocart.dto.order.OrderStatusResponse;
import icu.telepathystudios.echocart.model.User;
import icu.telepathystudios.echocart.model.order.Order;
import icu.telepathystudios.echocart.model.order.OrderStatus;
import icu.telepathystudios.echocart.model.profile.CustomerProfile;
import icu.telepathystudios.echocart.model.profile.PartnerProfile;
import icu.telepathystudios.echocart.repo.CustomerProfileRepo;
import icu.telepathystudios.echocart.repo.OrderRepo;
import icu.telepathystudios.echocart.repo.PartnerProfileRepo;
import icu.telepathystudios.echocart.repo.UserRepo;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class OrderService {

    private final OrderRepo orderRepo;
    private final UserRepo userRepo;
    private final CustomerProfileRepo customerProfileRepo;
    private final PartnerProfileRepo partnerProfileRepo;

    public OrderStatusResponse orderStatus(UUID orderId) {
        Order order = orderRepo.findById(orderId).orElseThrow(() ->
                new RuntimeException("Order not found"));
        UUID partnerId = order.getPartnerId();

        if(partnerId.toString().isEmpty()){
            throw new RuntimeException("PartnerId is empty");
        }

        PartnerProfile partnerProfile = partnerProfileRepo.findById(partnerId).orElseThrow(() ->
                new RuntimeException("Partner not found"));

        User user = userRepo.findById(partnerId).orElseThrow(() ->
                new RuntimeException("Partner not found"));

        return new OrderStatusResponse(order.getOrderStatus().toString(), partnerProfile.getName(), user.getPhoneNo());
    }

    public OrderResponse cancelOrder(UUID orderId) {
        Order order = orderRepo.findById(orderId).orElseThrow(() ->
                new RuntimeException("Order not found"));
        order.setOrderStatus(OrderStatus.CANCELLED);

        return mapToResponse(orderRepo.save(order));
    }

    public OrderResponse partnerActiveOrder() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String phoneNo = auth.getName();

        User user = userRepo.findByPhoneNo(phoneNo).orElseThrow(
                ()->
                        new RuntimeException("User not found")
        );


        List<Order> orders = orderRepo.findByPartnerId(user.getId());

        Optional<Order> acceptedOrder = orders.stream()
                .filter(ord -> OrderStatus.ACCEPTED.equals(ord.getOrderStatus())
                        || OrderStatus.IN_TRANSIT.equals(ord.getOrderStatus())
                        || OrderStatus.SHOPPING.equals(ord.getOrderStatus()))
                .findFirst();

        return acceptedOrder.map(this::mapToResponse).orElse(null);

    }

    public List<OrderResponse> partnerHistory() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String phoneNo = auth.getName();

        User user = userRepo.findByPhoneNo(phoneNo).orElseThrow(
                ()->
                        new RuntimeException("User not found")
        );

        List<Order> orders = orderRepo.findByPartnerId(user.getId());

        return orders.stream()
                .filter(ord -> OrderStatus.DELIVERED.equals(ord.getOrderStatus())
                        || OrderStatus.CANCELLED.equals(ord.getOrderStatus()))
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public void setStatus(UUID orderId, String status) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String phoneNo = auth.getName();

        User user = userRepo.findByPhoneNo(phoneNo).orElseThrow(
                ()->
                        new RuntimeException("User not found")
        );

        Order order =  orderRepo.findById(orderId).orElseThrow(() ->
                        new RuntimeException("Order not found"));

        order.setOrderStatus(OrderStatus.valueOf(status));

        orderRepo.save(order);
    }

    public record CustomerData(
            UUID customerId,
            String customerName,
            String customerNumber,
            String deliveryLocation,
            String deliveryCoordinates
    ) {}

    public OrderResponse createOrder(CreateOrderRequest request) {

        UUID customerId = getLoggedInCustomerId();

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

        UUID customerId = getLoggedInCustomerId();

        return orderRepo.findByCustomerId(customerId)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    public List<OrderResponse> getAvailableOrders() {

        return orderRepo.findByOrderStatusAndPartnerIdIsNull(OrderStatus.PENDING)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    public OrderResponse acceptOrder(UUID orderId) {

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String phoneNo = auth.getName();

        User user = userRepo.findByPhoneNo(phoneNo).orElseThrow(
                ()->
                        new RuntimeException("User not found")
        );

        Order order = orderRepo.findById(orderId)
                .orElseThrow(() ->
                        new RuntimeException("Order not found"));

        if (order.getPartnerId() != null) {
            throw new RuntimeException("Order already accepted");
        }

        order.setPartnerId(user.getId());
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

        CustomerData customerData = getCustomerData(order.getCustomerId());

        return new OrderResponse(
                order.getId(),
                customerData.customerName(),
                customerData.customerNumber(),
                customerData.deliveryLocation(),
                customerData.deliveryCoordinates(),
                order.getOrderStatus(),
                order.getOrderJson(),
                order.getEstimatedPrice()
        );
    }

    private UUID getLoggedInCustomerId() {

        Authentication auth =
                SecurityContextHolder.getContext().getAuthentication();

        if (auth == null) {
            throw new RuntimeException("Authentication required");
        }

        User user = userRepo.findByPhoneNo(auth.getName())
                .orElseThrow(() ->
                        new RuntimeException("User not found"));

        if (!user.getRole().equals("USER")) {
            throw new RuntimeException("Customers only");
        }

        return user.getId();
    }

    private CustomerData getCustomerData(UUID customerId) {

        User user = userRepo.findById(customerId)
                .orElseThrow(() ->
                        new RuntimeException("User not found"));

        CustomerProfile customerProfile =
                customerProfileRepo.findByUserId(customerId)
                        .orElseThrow(() ->
                                new RuntimeException("Customer profile not found"));

        return new CustomerData(
                customerId,
                customerProfile.getName(),
                user.getPhoneNo(),
                customerProfile.getAddress(),
                customerProfile.getCoordinates()
        );
    }
}
