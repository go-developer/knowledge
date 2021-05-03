---
title: redis字典的实现
categories:
  - redis
abbrlink: 39ae52d9
date: 2021-02-28 14:42:19
tags:
  - dict
description: redis字典的实现
cover: /img/redis/字典/普通状态下的字典.png
---

## 什么是字典

字典， 又称 **`符号表（symbol table）`** 、 **`关联数组（associative array）`** 或者 **`映射（map）`** ， 是一种用于保存 **`键值对（key-value pair）`** 的抽象数据结构。

**`键值对`** 在字典中， 一个键（key）可以和一个值（value）进行关联， 这些关联的键和值就被称为键值对。

## 字典的实现

### 底层实现

Redis 的字典使用 **`哈希表`** 作为底层实现， 一个哈希表里面可以有多个哈希表节点， 而每个哈希表节点就保存了字典中的一个键值对。

### 哈希表节点定义

代码位置 : `dict.h`

```c
typedef struct dictEntry {
    void *key;  //字典key
    union {     //数据值
        void *val;
        uint64_t u64;
        int64_t s64;
        double d;
    } v;
    struct dictEntry *next; //指向下个哈希表节点，形成链表，hash键冲突时才被用到
} dictEntry;
```

- 哈希表节点使用dictEntry结构表示， 每个dictEntry结构都保存着一个键值对
- key属性保存着键值对中的键， 而v属性则保存着键值对中的值， 其中键值对的值可以是 **`一个指针`** ， 或者是一个 **`uint64_t整数`** ， 又或者是一个 **`int64_t整数`**
- next属性是指向另一个哈希表节点的指针， 这个指针可以将多个哈希值相同的键值对连接在一起， 以此来 **`解决键冲突（collision）的问题`** 。

### 哈希表定义

代码位置 : `dict.h`

```c
typedef struct dictht {
    dictEntry **table;  //哈希表数组
    unsigned long size; //哈希表大小
    unsigned long sizemask; //哈希表大小掩码，用于计算索引值 总是等于 size - 1
    unsigned long used; //该哈希表已有节点的数量
} dictht;
```

- table 属性是 **`一个数组`**， 数组中的每个元素都是一个指向 **`dictEntry`** 结构的指针， 每个 dictEntry 结构保存着一个键值对。
- size 属性记录了 **`哈希表的大小`**
- used 属性记录了 **`哈希表目前已有节点（键值对）的数量`**。
- sizemask 属性的值 **`总是等于 size - 1`** ， 这个属性和哈希值一起决定一个键应该被放到 table 数组的哪个索引上面。

### 字典定义

代码位置 : `dict.h`

```c
typedef struct dict {
    dictType *type;             //类型特定函数
    void *privdata;             //私有数据
    dictht ht[2];               //哈希表
    long rehashidx;             //rehash 索引 当 rehash 不在进行时，值为 -1
    unsigned long iterators;    //目前正在运行的安全迭代器的数量
} dict;
```

- type属性和privdata属性是针对不同类型的键值对， 为创建多态字典而设置的
- ht属性是一个包含两个项的数组， 数组中的每个项都是一个dictht哈希表， 一般情况下， 字典只使用 ht[0] 哈希表， ht[1] 哈希表只会在对 ht[0] 哈希表进行 rehash 时使用
- 除了 ht[1] 之外， 另一个和 rehash 有关的属性就是rehashidx： 它记录了 rehash 目前的进度， 如果目前没有在进行 rehash ， 那么它的值为 -1 。

**`eg. 空字典`**

![空字典](/img/redis/字典/空字典.png)

**`eg. 普通状态下的字典(没有进行 rehash)`**

![普通状态下的字典](/img/redis/字典/普通状态下的字典.png)

### 哈希算法

当要将一个新的键值对添加到字典里面时， 程序需要先根据键值对的键计算出哈希值和索引值， 然后再根据索引值， 将包含新键值对的哈希表节点放到哈希表数组的指定索引上面。

Redis 计算哈希值和索引值的方法如下：

```c
// 使用字典设置的哈希函数，计算键 key 的哈希值
hash = dict->type->hashFunction(key);

// 使用哈希表的 sizemask 属性和哈希值，计算出索引值
// 根据情况不同， ht[x] 可以是 ht[0] 或者 ht[1]
index = hash & dict->ht[x].sizemask;
```

**`eg. 将一个键值对 k0 和 v0 添加到一个新建立的字典里面`**

![添加键值对后的字典](/img/redis/字典/普通状态下的字典.png)

- 程序先使用语句：hash = dict->type->hashFunction(k0), 计算键 k0 的哈希值
- 假设计算得出的哈希值为 8 ， 那么程序会继续使用语句：index = hash & dict->ht[0].sizemask = 8 & 3 = 0;
- 计算出键 k0 的索引值 0 ， 这表示包含键值对 k0 和 v0 的节点应该被放置到哈希表数组的索引 0 位置上

> 【知识点】
> 当字典被用作数据库的底层实现，或者哈希键的底层实现时，Redis 使用 **MurmurHash2** 算法来计算键的哈希值。

### 哈希冲突的解决

当有 **两个或以上数量** 的键被分配到了哈希表数组的同一个索引上面时， 我们称这些键发生了冲突（collision）。

**字典哈希冲突解决方案** 参见 : [哈希冲突解决方案](/archives/c1cf4e81.html)

### rehash原理及实现

**rehash原理实现** 参见 : [rehash原理](/archives/72cf4df.html)

## 字典的主要API

|          函数          |                                     作用                                      |        时间复杂度         |
| :--------------------: | :---------------------------------------------------------------------------: | :-----------------------: |
|       dictCreate       |                              创建一个新的字典。                               |           O(1)            |
|        dictAdd         |                          将指定的键值对添加到字典里                           |           O(1)            |
|       dictAddRaw       |                     基础的向hash表中新增一个键值对的方法                      |           O(1)            |
|    dictGetIterator     |                         获取迭代器, 不安全, safe = 0                          |           O(1)            |
|  dictGetSafeIterator   |                          获取迭代器, 安全, safe = 1                           |           O(1)            |
|  dictReleaseIterator   |                                  释放迭代器                                   |           O(1)            |
|        dictNext        |                          依据迭代器获取下一个键值对                           |           O(1)            |
|    dictGetRandomKey    |                              随机获取一个键值对                               |           O(1)            |
|    dictGetSomeKeys     |                             随机返回指定数量的key                             |           O(1)            |
|       dictEmpty        |                           清空字典数据但不释放空间                            |           O(1)            |
|      dictReplace       | 将给定的键值对添加到字典里面， 如果键已经存在于字典，那么用新值取代原有的值。 |           O(1)            |
|        dictFind        |                                 查找指定的key                                 |           O(1)            |
|     dictFetchValue     |                               返回指定的key的值                               |           O(1)            |
|       dictDelete       |                      从字典中删除给定键所对应的键值对。                       |           O(1)            |
|      dictRelease       |                   释放给定字典，以及字典中包含的所有键值对                    | O(N), N为字典中键值对数量 |
|    dictEnableResize    |                             启用redis空间再次分配                             |           O(1)            |
|   dictDisableResize    |            禁用redis空间再次分配(比如: rehash期间ht[0]禁用resize)             |           O(1)            |
|       dictResize       |          重计算字典大小,将字典容量设置为可以容纳当前字典数据的最小值          |           O(1)            |
|       dictRehash       |                               对字典进行rehash                                | O(N),N为字典中键值对数量  |
| dictRehashMilliseconds |          执行rehash操作，指定运行时间，此时间内rehash可能未最终完成           | O(N),N为字典中键值对数量  |
