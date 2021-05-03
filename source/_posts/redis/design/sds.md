---
title: redis之动态字符串(SDS)的设计与实现
categories:
  - redis
abbrlink: 616b813e
date: 2020-09-25 18:44:05
description: redis之动态字符串(SDS)的设计与实现
cover: /img/category/redis.jpeg
tags:
  - sds
  - 动态字符串
  - redis实现原理
---

### SDS(Simple Dynamic String)定义

源码中定义 :

```c
typedef char *sds;
```

!!! note 总结
    sds类型实际为 char * 的别名,这样做的好处是，可以复用很多C的原生函数库。

## SDS的结构体定义sdshdr

sdshdr有好`五个`类别，它们分别是：`sdshdr5`，`sdshdr8`，`sdshdr16`，`sdshdr32`，`sdshdr64`，其中sdshdr5是不使用的

``` c
/* Note: sdshdr5 is never used, we just access the flags byte directly. However is here to document the layout of type 5 SDS strings. */
struct __attribute__ ((__packed__)) sdshdr5 {
    unsigned char flags; /* 3 lsb of type, and 5 msb of string length */
    char buf[];
};
struct __attribute__ ((__packed__)) sdshdr8 {
    uint8_t len; /* 已使用的长度(字符串真实长度) */
    uint8_t alloc; /* 字符串最大容量,不包含字符串的结尾 \0 */
    unsigned char flags; /* 总是占用一个字节。其中的最低3个bit用来表示header的类型,剩余5位未使用 */
    char buf[];
};
struct __attribute__ ((__packed__)) sdshdr16 {
    uint16_t len; /* 已使用的长度(字符串真实长度) */
    uint16_t alloc; /* 字符串最大容量,不包含字符串的结尾 \0 */
    unsigned char flags; /* 总是占用一个字节。其中的最低3个bit用来表示header的类型,剩余5位未使用 */
    char buf[];
};
struct __attribute__ ((__packed__)) sdshdr32 {
    uint32_t len; /* 已使用的长度(字符串真实长度) */
    uint32_t alloc; /* 字符串最大容量,不包含字符串的结尾 \0 */
    unsigned char flags; /* 总是占用一个字节。其中的最低3个bit用来表示header的类型,剩余5位未使用 */
    char buf[];
};
struct __attribute__ ((__packed__)) sdshdr64 {
    uint64_t len; /* 已使用的长度(字符串真实长度) */
    uint64_t alloc; /* 字符串最大容量,不包含字符串的结尾 \0 */
    unsigned char flags; /* 总是占用一个字节。其中的最低3个bit用来表示header的类型,剩余5位未使用 */
    char buf[];
};
```

!!! note  结构体说明
    `len` : 字符串的长度
    `alloc` : 字符串的容量
    `flags` : 用低三位表示header类型,高五位未使用,为何是低三位表示,见下方
    `buf[]` : 实际存储的字符串

## 细节说明

### __attribute__ ((packed)) 说明

!!! note __attribute__ ((packed)) 说明
    attribute ((packed))实际作用是 **`取消编译阶段的内存优化对齐功能。`**
    例如：struct aa {char a; int b;}; sizeof(aa) == 8;但是struct attribute ((packed)) aa {char a; int b;}; sizeof(aa) == 5;
    这个很重要，redis源码中不是直接对sdshdr某一个类型操作，往往参数都是sds，而sds就是结构体中的buf，在后面的源码分析中，你可能会经常看见`s[-1]`这种魔法一般的操作，而按照sdshdr内存分布s[-1]就是sdshdr中flags变量，由此可以获取到该sds指向的字符串的类型。

### 常量定义

```c
#define SDS_TYPE_5  0
#define SDS_TYPE_8  1
#define SDS_TYPE_16 2
#define SDS_TYPE_32 3
#define SDS_TYPE_64 4
#define SDS_TYPE_MASK 7
#define SDS_TYPE_BITS 3
```

!!! note 为何是低三位表示类型
    SDS_TYPE只占用了`0,1,2,3,4`五个数字，正好占用三位，我们就可以使用`flags&SDS_TYPE_MASK`来获取动态字符串对应的字符串类型

## SDS中的宏定义函数

### 根据指向buf的sds变量s,得到sdshdr对应的指针变量

```c
#define SDS_HDR_VAR(T,s) struct sdshdr##T *sh = (void*)((s)-(sizeof(struct sdshdr##T)));
```

### 根据指向buf的sds变量s,得到sdshdr对应的指针地址

```c
#define SDS_HDR(T,s) ((struct sdshdr##T \*)((s)-(sizeof(struct sdshdr##T))));
```

### 获取sdshdr5字符串类型的长度

```c
#define SDS_TYPE_5_LEN(f) ((f)>>SDS_TYPE_BITS)
```

!!! note c中的##语法
    `##` 是c语言中的连接符, 前加 \#\# 或者后加 ## 将标记作为一个合法的标识符的一部分，不是字符串．`多用于多行的宏定义中`。+
    本宏声明中,SDS_HDR_VAR(8,s) 相当于 struct sdshdr8 \*sh = (void\*)((s)-(sizeof(struct sdshdr8)));

## SDS相关内联函数

### 获取字符串长度

```c
static inline size_t sdslen(const sds s) {
    //获取字符串类型flag
    unsigned char flags = s[-1];
    switch(flags&SDS_TYPE_MASK) {
        case SDS_TYPE_5:
            return SDS_TYPE_5_LEN(flags);
        case SDS_TYPE_8:
            return SDS_HDR(8,s)->len;
        case SDS_TYPE_16:
            return SDS_HDR(16,s)->len;
        case SDS_TYPE_32:
            return SDS_HDR(32,s)->len;
        case SDS_TYPE_64:
            return SDS_HDR(64,s)->len;
    }
    return 0;
}
```

!!! note 知识点
    该处就使用到了 **`取消编译阶段的内存优化对齐功能`** ，直接使用s[-1]获取到flags成员的值，然后根据flags&&SDS_TYPE_MASK来获取到动态字符串对应的类型进而 **`获取动态字符串的长度`**,至于 **`灵性的 s[-1]操作，没研究明白，后续补充`**

### 获取字符串可用空间

```c
static inline size_t sdsavail(const sds s) {
    unsigned char flags = s[-1];
    switch(flags&SDS_TYPE_MASK) {
        case SDS_TYPE_5: {
            return 0;
        }
        case SDS_TYPE_8: {
            SDS_HDR_VAR(8,s);
            return sh->alloc - sh->len;
        }
        case SDS_TYPE_16: {
            SDS_HDR_VAR(16,s);
            return sh->alloc - sh->len;
        }
        case SDS_TYPE_32: {
            SDS_HDR_VAR(32,s);
            return sh->alloc - sh->len;
        }
        case SDS_TYPE_64: {
            SDS_HDR_VAR(64,s);
            return sh->alloc - sh->len;
        }
    }
    return 0;
}
```

!!! note 知识点
    获取动态字符串可使用的空间，从这里可以看出来，SDS和我平常所用到的C语言的原生字符串有差别，因为从获取可用空间的计算方法来看，**`并未考虑到字符串需要以\0结尾`**，因为 **`结构体本身带有长度的成员len`**，不需要\\0来做字符串结尾的判定，而且不使用\\0作为结尾有很多好处，**`可以存储的类型多样性就提高了`**

### 设置sds的长度

```c
static inline void sdssetlen(sds s, size_t newlen) {
    unsigned char flags = s[-1];
    switch(flags&SDS_TYPE_MASK) {
        case SDS_TYPE_5:
            {
                unsigned char *fp = ((unsigned char*)s)-1;
                *fp = SDS_TYPE_5 | (newlen << SDS_TYPE_BITS);
            }
            break;
        case SDS_TYPE_8:
            SDS_HDR(8,s)->len = newlen;
            break;
        case SDS_TYPE_16:
            SDS_HDR(16,s)->len = newlen;
            break;
        case SDS_TYPE_32:
            SDS_HDR(32,s)->len = newlen;
            break;
        case SDS_TYPE_64:
            SDS_HDR(64,s)->len = newlen;
            break;
    }
}
```

### 增加sds的长度

```c
static inline void sdsinclen(sds s, size_t inc) {
    unsigned char flags = s[-1];
    switch(flags&SDS_TYPE_MASK) {
        case SDS_TYPE_5:
            {
                unsigned char *fp = ((unsigned char*)s)-1;
                unsigned char newlen = SDS_TYPE_5_LEN(flags)+inc;
                *fp = SDS_TYPE_5 | (newlen << SDS_TYPE_BITS);
            }
            break;
        case SDS_TYPE_8:
            SDS_HDR(8,s)->len += inc;
            break;
        case SDS_TYPE_16:
            SDS_HDR(16,s)->len += inc;
            break;
        case SDS_TYPE_32:
            SDS_HDR(32,s)->len += inc;
            break;
        case SDS_TYPE_64:
            SDS_HDR(64,s)->len += inc;
            break;
    }
}
```

### 获取sds已分配空间(容量)的大小

```c
static inline size_t sdsalloc(const sds s) {
    unsigned char flags = s[-1];
    switch(flags&SDS_TYPE_MASK) {
        case SDS_TYPE_5:
            return SDS_TYPE_5_LEN(flags);
        case SDS_TYPE_8:
            return SDS_HDR(8,s)->alloc;
        case SDS_TYPE_16:
            return SDS_HDR(16,s)->alloc;
        case SDS_TYPE_32:
            return SDS_HDR(32,s)->alloc;
        case SDS_TYPE_64:
            return SDS_HDR(64,s)->alloc;
    }
    return 0;
}
```

### 设置sds已分配空间(容量)的大小

```c
static inline void sdssetalloc(sds s, size_t newlen) {
    unsigned char flags = s[-1];
    switch(flags&SDS_TYPE_MASK) {
        case SDS_TYPE_5:
            /* Nothing to do, this type has no total allocation info. */
            break;
        case SDS_TYPE_8:
            SDS_HDR(8,s)->alloc = newlen;
            break;
        case SDS_TYPE_16:
            SDS_HDR(16,s)->alloc = newlen;
            break;
        case SDS_TYPE_32:
            SDS_HDR(32,s)->alloc = newlen;
            break;
        case SDS_TYPE_64:
            SDS_HDR(64,s)->alloc = newlen;
            break;
    }
}
```

## C字符串与SDS对比

|                  C字符串                   |                   SDS                    |
| :----------------------------------------: | :--------------------------------------: |
|       获取字符串长度时间复杂度 O(N)        |      获取字符串长度时间复杂度 O(1)       |
|       API不安全，可能造成缓冲区溢出        |     API是安全的，不会造成缓冲区溢出      |
| 修改字符串长度N次，必然要执行 N 次内存分配 | 修改字符串长度N次，至多执行 N 次内存分配 |
|              只能保存文本数据              |         可以保存文本或二进制数据         |
|      可使用所有 <string.h>库中的函数       |     可使用部分 <string.h>库中的函数      |
