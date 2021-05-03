---
title: REDIS字符串操作基本命令
categories:
  - redis
abbrlink: dc770c79
date: 2021-02-09 19:17:23
description: redis字符串相关命令
tags:
  - redis命令
---

## 命令汇总

![REDIS字符串命令](/img/redis/命令/REDIS字符串.png)

## 基础命令

### GET

**`GET key`** : 获取key的值,当key不存在时,返回空字符串

**`MGET [key ...]`** : 批量获取指定的key的值

### SET

**`SET key value`** : 设置key的值,若此key之前已存在,会  **`覆盖`** 之前的值

**`SET [key value ...]`** : 批量设置指定key的值

### INCR

 **`INCR key`** : 对指定的key **`自增1`**,此命令要求  **`value 必须是整型`**, 否则此命令会报错  **`ERR value is not an integer or out of range`**

**`DECR key`** : 和INCR命令相同,此为对key值  **`自减1`**

**`INCRBY key increment`** : 和 INCR 命令相同, 区别是此命令可以 **`指定自增的值`**, INCR key 相当于 INCRBY key 1

**`DECRBY key decrement`** : 和 DECR 命令相同, 区别是此命令可以 **`指定自减的值`**, DECRBY key 相当于 DECR key 1

**`INCRBYFLOAT key increment`** : 包含INCRBY支持的全部能力,区别是此命令 **`支持双精度浮点数`** ,而INCRBY不支持

**`DECRBYFLOAT key decrement`** : 包含DECRBY支持的全部能力,区别是此命令 **`支持双精度浮点数`** ,而DECRBY不支持

### BIT操作

个人觉得实用性有限,此处未做整理

## 应用

### SET的应用

SET 除了基础 set key value 之外, 还包含可选参数:  **`[EX seconds|PX milliseconds|KEEPTTL] [NX|XX]`**

#### 数据缓存

当我们有某一类查询结果需要缓存但是又不希望长久有效时,可以使用 SET key value ex 1200,此示例表示当前key有效期1200s,到期自动清除

#### 分布式锁

set key value nx 当 **`key不存在时`** 会设置一个key, 当key已经存在, 不会执行任何操作, 可以根据set的结果判断是否获取到锁,获取到了,才执行后续逻辑

使用上面的命令会有一个问题,一旦忘记释放锁,或大段逻辑超时,此锁会被永久持有,永不释放,最终会导致系统崩溃

对此命令优化如下 :  **`SET key value PX 100 nx`** , 这样保证了锁至多持有100ms,不会引发雪崩问题

## 字符串实现原理

[字符串SDS原理与实现](/archives/616b813e.html)

