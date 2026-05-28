package icu.telepathystudios.echocart;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.transaction.annotation.EnableTransactionManagement;

@SpringBootApplication
@EnableTransactionManagement
public class EchoCartApplication {

    public static void main(String[] args) {
        SpringApplication.run(EchoCartApplication.class, args);
    }

}
