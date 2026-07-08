package icu.telepathystudios.echocart.repo;

import icu.telepathystudios.echocart.model.order.Order;
import icu.telepathystudios.echocart.model.order.OrderStatus;
import org.jspecify.annotations.NonNull;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface OrderRepo extends JpaRepository<Order, UUID> {
    Optional<Order> findById(@NonNull UUID orderId);
    List<Order> findByCustomerId(UUID customerId);
    List<Order> findByPartnerId(UUID partnerId);
    List<Order> findByOrderStatus(OrderStatus status);
}
