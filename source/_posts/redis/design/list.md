---
title: redis链表的设计与实现
categories:
  - redis
abbrlink: ca87edab
date: 2020-09-27 19:20:38
tags:
  - 链表
cover: /img/redis/链表/由list和listNode构成的链表.png
description: redis链表的设计与实现
---


## 链表简介

链表提供了 **高效的节点重排能力**， 以及 **顺序性的节点访问** 方式， 并且可以通过增删节点来灵活地调整链表的长度。作为一种常用数据结构， 链表内置在很多高级的编程语言里面， 因为 Redis 使用的 C 语言并没有内置这种数据结构， 所以 Redis 构建了自己的链表实现。

## 链表及链表节点的实现

### 源码定义

源码位置 : `adlist.h`

```c
/*
 * list的节点定义
 */
typedef struct listNode {
    struct listNode *prev;  //前驱指针
    struct listNode *next;  //后继指针
    void *value;            //节点值
} listNode;

/*
 * list定义
 */
typedef struct list {
    listNode *head;                     //头节点指针
    listNode *tail;                     //尾节点指针
    void *(*dup)(void *ptr);            //复制链表节点所保存的值
    void (*free)(void *ptr);            //释放链表节点所保存的值
    int (*match)(void *ptr, void *key); //对比链表节点所保存的值和另一个输入值是否相等
    unsigned long len;                  //链表长度
} list;
```

- **`head`** : 表头指针
- **`tail`** : 表尾指针
- **`len`** : 链表长度计数器
- **`dup`** : 函数用于复制链表节点所保存的值
- **`free`** : 函数用于释放链表节点所保存的值
- **`match`** : 函数则用于对比链表节点所保存的值和另一个输入值是否相等

![由list和listNode构成的链表](/img/redis/链表/由list和listNode构成的链表.png)

### 迭代器定义

代码位置 : `adlist.h`

```c
/**
 * 迭代器
 */
typedef struct listIter {
    listNode *next; //当前节点
    int direction;  //迭代方向
} listIter;
#define AL_START_HEAD 0 //从表头向表尾进行迭代
#define AL_START_TAIL 1 //从表尾到表头进行迭代
```

### redis链表特性

- **双端** : 每个节点都有prev与next指针, 获取某个节点的前置节点和后置节点时间复杂度均为O(1)
- **无环** : 表头节点的prev与表尾节点的next均指向NULL,链表的访问以 NULL结束
- **带表头指针与表尾指针** : 即list结构中的head指针与tail指针,获取表头节点与表尾节点的时间复杂度为O(1)
- **带链表长度计数器** : 即list结构中的len属性,湖区链表长度的时间复杂度O(1)
- **多态** : 链表节点使用 void * 来保存节点值，并且可以通过list结构的dup、free、match三个属性尾节点值设置类型特定函数,所以链表可以用于保存各种类型不同的值

## 链表和链表节点的API

|        函数         |                                     作用                                      |                    时间复杂度                    |
| :-----------------: | :---------------------------------------------------------------------------: | :----------------------------------------------: |
|  listSetDupMethod   |                   将给定的函数设置为链表的节点值复制函数。                    |                       O(1)                       |
|  listGetDupMethod   |                    返回链表当前正在使用的节点值复制函数。                     |  复制函数可以通过链表的 dup 属性直接获得， O(1)  |
|  listSetFreeMethod  |                   将给定的函数设置为链表的节点值释放函数。                    |                       O(1)                       |
|     listGetFree     |                    返回链表当前正在使用的节点值释放函数。                     | 释放函数可以通过链表的 free 属性直接获得， O(1)  |
| listSetMatchMethod  |                   将给定的函数设置为链表的节点值对比函数。                    |                       O(1)                       |
| listGetMatchMethod  |                    返回链表当前正在使用的节点值对比函数。                     | 对比函数可以通过链表的 match 属性直接获得， O(1) |
|     listLength      |                     返回链表的长度（包含了多少个节点）。                      |  链表长度可以通过链表的 len 属性直接获得， O(1)  |
|      listFirst      |                             返回链表的表头节点。                              | 表头节点可以通过链表的 head 属性直接获得， O(1)  |
|      listLast       |                             返回链表的表尾节点。                              | 表尾节点可以通过链表的 tail 属性直接获得， O(1)  |
|    listPrevNode     |                           返回给定节点的前置节点。                            | 前置节点可以通过节点的 prev 属性直接获得， O(1)  |
|    listNextNode     |                           返回给定节点的后置节点。                            | 后置节点可以通过节点的 next 属性直接获得， O(1)  |
|    listNodeValue    |                        返回给定节点目前正在保存的值。                         |  节点值可以通过节点的 value 属性直接获得， O(1)  |
|     listCreate      |                       创建一个不包含任何节点的新链表。                        |                       O(1)                       |
|   listAddNodeHead   |                将一个包含给定值的新节点添加到给定链表的表头。                 |                       O(1)                       |
|   listAddNodeTail   |                将一个包含给定值的新节点添加到给定链表的表尾。                 |                       O(1)                       |
|   listInsertNode    |            将一个包含给定值的新节点添加到给定节点的之前或者之后。             |                       O(1)                       |
|    listSearchKey    |                      查找并返回链表中包含给定值的节点。                       |               O(N) ， N 为链表长度               |
|      listIndex      |                         返回链表在给定索引上的节点。                          |               O(N) ， N 为链表长度               |
|     listDelNode     |                            从链表中删除给定节点。                             |                       O(1)                       |
|     listRotate      | 将链表的表尾节点弹出，然后将被弹出的节点插入到链表的表头， 成为新的表头节点。 |                       O(1)                       |
|       listDup       |                           复制一个给定链表的副本。                            |               O(N) ， N 为链表长度               |
|     listRelease     |                     释放给定链表，以及链表中的所有节点。                      |               O(N) ， N 为链表长度               |
|      listEmpty      |                      移除链表所有的节点，但是不销毁链表                       |               O(N) ， N 为链表长度               |
|   listGetIterator   |      获取list的迭代器,初始化后,每次调用listNext()，返回链表的下一个元素       |                       O(1)                       |
|      listNext       |             获取链表的下一个元素, 入参迭代器由listGetIterator获得             |                       O(1)                       |
| listReleaseIterator |                               释放迭代器的内存                                |                       O(1)                       |
|     listRewind      |                 从私有的迭代器中创建一个从头至尾顺序的迭代器                  |                       O(1)                       |
|   listRewindTail    |                 从私有的迭代器中创建一个从尾至头顺序的迭代器                  |                       O(1)                       |
|      listJoin       |               将一个列表o追加到另一个列表l的尾部，同时清空列表o               |               O(N),N为列表o的长度                |
