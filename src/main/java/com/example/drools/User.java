package com.example.drools;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.ToString;

/**
 * @author sunchuanfu
 * @date 2021/1/26 16:32
 */
@Data
@ToString
@NoArgsConstructor
@AllArgsConstructor
public class User {
    private String name;
    private String age;
    private String address;
    private String phone;
    private String sex;
}