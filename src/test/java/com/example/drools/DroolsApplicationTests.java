package com.example.drools;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.kie.api.runtime.KieSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
class DroolsApplicationTests {

    @Autowired
    private KieSession session;

    @Test
    void contextLoads() {
        User user = new User();
        user.setAddress("上海");
        // user.setAddress("北京");
        user.setAge("20");
        user.setName("echo");
        user.setPhone("136123456");
        user.setSex("1");
        // 插入用户
        session.insert(user);
        // 执行规则
        session.fireAllRules();
    }

    /**
     * 记得执行完成之后释放资源
     */
    @AfterEach
    public void runDispose() {
        session.dispose();
    }


}
