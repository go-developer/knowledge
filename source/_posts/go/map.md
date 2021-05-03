---
title: GO数据类型之哈希表
categories:
  - go
abbrlink: 7db7380e
date: 2020-10-21 21:55:00
tags:
  - GO数据类型
  - 哈希表
description: map的原理与实现
cover: /img/go/hash.jpeg
---

## 涉及的代码说明

代码版本:  **`https://github.com/golang/go.git@b4c8b67adcd39da54f210bef5c201b1df8124d73`**

## 什么是哈希表

**`哈希表`** 是一种古老的数据结构，在 1953 年就有人使用拉链法实现了哈希表，它能够根据键（Key）直接访问内存中的存储位置，也就是说我们能够直接通过键找到该键对应的一个值。

## 哈希表的关键

 **`哈希函数`** 与  **`冲突解决`**

## 哈希函数

实现哈希表的关键点在于 **`如何选择哈希函数`** ，哈希函数的选择在很大程度上能够决定 **`哈希表的读写性能`** ，在理想情况下，哈希函数应该能够将 **`不同键映射到不同的索引上`** ，这要求哈希函数 **`输出范围大于输入范围`** ，但是由于键的数量会远远大于映射的范围，所以在实际使用时，这个理想的结果是不可能实现的。

比较实际的方式是让哈希函数的结果能够尽可能的 **`均匀分布`** ，然后通过工程上的手段解决 **`哈希碰撞`** 的问题，但是哈希的结果一定要 **`尽可能均匀`** ，结果不均匀的哈希函数会造成更多的冲突并导致更差的读写性能。

在一个使用结果较为均匀的哈希函数中，哈希的增删改查都需要 **`O(1)`** 的时间复杂度，但是非常不均匀的哈希函数会导致所有的操作都会占用最差 **`O(n)`** 的复杂度，所以在哈希表中使用好的哈希函数是至关重要的。

## 冲突解决

### 开放寻址法

开放寻址法核心思想是 **`对数组中的元素依次探测和比较`** 以判断目标键值对是否存在于哈希表中，如果我们使用开放寻址法来实现哈希表，那么在支撑哈希表的数据结构就是数组，不过因为数组的长度有限，存储 (author, zhangdeman) 这个键值对时会从如下的索引开始遍历：

```go
index := hash("author") % array.len
```

当我们向当前哈希表写入新的数据时发生了冲突，就会将键值对写入到下一个索引不为空的位置：

![开放寻址哈希算法](/img/go/开放寻址.png)

如上图所示，当 Key3 与已经存入哈希表中的两个键值对 Key1 和 Key2 发生冲突时，Key3 会被写入 Key2 后面的空闲内存中；当我们再去读取 Key3 对应的值时就会先对键进行哈希并取模，这会帮助我们找到 Key1，因为 Key1 与我们期望的键 Key3 不匹配，所以会继续查找后面的元素，直到内存为空或者找到目标元素。

当需要查找某个键对应的值时，就会从 **`索引的位置`** 开始对数组进行 **`线性`** 探测，找到目标键值对或者空内存就意味着这一次查询操作的结束。

开放寻址法中对性能影响最大的就是 **`装载因子`** ，它是数组中 **`元素的数量`** 与 **`数组大小`** 的比值，随着装载因子的增加，线性探测的平均用时就会逐渐增加，这会同时影响哈希表的读写性能，当装载率超过 **`70%`** 之后，哈希表的性能就会急剧下降，而一旦装载率达到 100%，整个哈希表就会完全失效，这时查找和插入任意元素的时间复杂度都是 𝑂(𝑛) 的，它们可能需要遍历数组中全部的元素，所以在实现哈希表时一定要时刻 **`关注装载因子的变化`** 。

## 拉链法

与开放地址法相比，拉链法是哈希表中最常见的实现方法，大多数的编程语言都用拉链法实现哈希表，它的实现比较开放地址法稍微复杂一些，但是平均查找的长度也比较短，各个用于存储节点的内存都是 **`动态申请的`**，可以节省比较多的存储空间。

实现拉链法一般会使用 **`数组`** + **`链表`** ，不过有一些语言会在拉链法的哈希中引入 **`红黑树`** 以优化性能，拉链法会使用 **`链表数组`** 作为哈希底层的数据结构，我们可以将它看成一个 **`可以扩展的二维数组`**

![拉链法哈希算法](/img/go/拉链法.png)

如上图所示，当我们需要将一个键值对 (Key6, Value6) 写入哈希表时，键值对中的键 Key6 都会先经过一个哈希函数，哈希函数返回的哈希会帮助我们选择一个桶，和开放地址法一样，选择桶的方式就是直接对哈希返回的结果取模

```go
index := hash("Key6") % array.len
```

选择了 5 号桶之后就可以遍历当前桶中的链表了，在遍历链表的过程中会遇到以下两种情况：

- 找到键相同的键值对 —— **`更新`** 键对应的值
- 没有找到键相同的键值对 —— 在链表的 **`末尾追加`** 新键值对

将键值对写入哈希之后，要通过某个键在其中获取映射的值，就会经历如下的过程

- 选择数据桶
- 遍历桶中的链表
- 找到对应key停止遍历或遍历结束后不存在

在一个性能比较好的哈希表中，每一个桶中都应该有 0~1 个元素，有时会有 2~3 个，很少会超过这个数量， **`计算哈希`** 、 **`定位桶`** 和 **`遍历链表`**

```go
装载因子 := 元素数量 / 桶数量
```

与开放地址法一样，拉链法的 **`装载因子越大，哈希的读写性能就越差`** ，在一般情况下使用拉链法的哈希表装载因子都 **`不会超过 1`** ，当哈希表的装载因子较大时就会 **`触发哈希的扩容`** ，创建更多的桶来存储哈希中的元素，保证性能不会出现严重的下降。如果有 1000 个桶的哈希表存储了 10000 个键值对，它的性能是保存 1000 个键值对的 1/10，但是仍然比在链表中直接读写好 1000 倍。

## 数据结构

Go 语言运行时同时使用了多个数据结构组合表示哈希表，其中使用 **`hmap`** , 代码位置:  **`src/runtime/map.go@hmap`**

```go
// A header for a Go map.
type hmap struct {
  // Note: the format of the hmap is also encoded in cmd/compile/internal/gc/reflect.go.
  // Make sure this stays in sync with the compiler's definition.
  count     int // # live cells == size of map.  Must be first (used by len() builtin)
  flags     uint8
  B         uint8  // log_2 of # of buckets (can hold up to loadFactor * 2^B items)
  noverflow uint16 // approximate number of overflow buckets; see incrnoverflow for details
  hash0     uint32 // hash seed

  buckets    unsafe.Pointer // array of 2^B Buckets. may be nil if count==0.
  oldbuckets unsafe.Pointer // previous bucket array of half the size, non-nil only when growing
  nevacuate  uintptr        // progress counter for evacuation (buckets less than this have been evacuated)

  extra *mapextra // optional fields
}
```

- **`count`** 表示当前哈希表中的元素数量
- **`B`** 表示当前哈希表持有的 buckets 数量，但是因为哈希表中桶的数量都 2 的倍数，所以该字段会 **`存储对数`** ，也就是 len(buckets) == 2^B
- **`hash0`** 是哈希的种子，它能为哈希函数的结果引入随机性，这个值在 **`创建哈希表时确定`** ，并在调用哈希函数时作为参数传入
- **`oldbuckets`** 是哈希在扩容时用于保存之前 buckets 的字段，它的大小是 **`当前 buckets 的一半`**

![hmap示意](/img/go/hmap.png)

如上图所示哈希表 hmap 的桶就是 bmap，每一个 bmap 都能存储 **`8`** (此处为方便，只画了三个) 个键值对，当哈希表中存储的数据过多，单个桶无法装满时就会使用 **`extra.overflow`** 中桶存储溢出的数据。上述 **`两种不同的桶在内存中是连续存储的`** ，我们在这里将它们分别称为 **`正常桶`** 和 **`溢出桶`** ，上图中黄色的 bmap 就是正常桶，橙色的 bmap 是溢出桶，溢出桶是在 Go 语言还使用 C 语言实现时就使用的设计，由于它能够减少扩容的频率所以一直使用至今。

这个桶的结构体 bmap 在 Go 语言源代码中的定义只包含一个简单的 **`tophash`** 字段，tophash 存储了 **`键的哈希的高 8 位`** ，通过比较不同键的哈希的高 8 位可以 **`减少访问键值对次数`** 以提高性能(代码位置:  **`src/runtime/map.go@bmap`** )

```go
// A bucket for a Go map.
type bmap struct {
  // tophash generally contains the top byte of the hash value
  // for each key in this bucket. If tophash[0] < minTopHash,
  // tophash[0] is a bucket evacuation state instead.
  tophash [bucketCnt]uint8
  //Followed by bucketCnt keys and then bucketCnt elems.
  // Followed by bucketCnt keys and then bucketCnt elems.
  // NOTE: packing all the keys together and then all the elems together makes the
  // code a bit more complicated than alternating key/elem/key/elem/... but it allows
  // us to eliminate padding which would be needed for, e.g., map[int64]int8.
  // Followed by an overflow pointer.
```

bmap 结构体其实 **`不止`** 包含 tophash 字段，由于哈希表中可能存储不同类型的键值对并且 Go 语言也不支持泛型，所以键值对占据的内存空间大小只能在 **`编译时进行推导`** ，这些字段在运行时也都是 **`通过计算内存地址的方式直接访问`** 的，所以它的定义中就没有包含这些字段，但是我们能根据编译期间的 **`cmd/compile/internal/reflect.go@bmap`** 函数对它的结构重建.

```go
type bmap struct {
  topbits  [8]uint8
  keys     [8]keytype
  values   [8]valuetype
  pad      uintptr
  overflow uintptr
}
```

如果哈希表存储的数据逐渐增多，我们会对哈希表进行 **`扩容`** 或者使用 **`额外的桶存储溢出的数据`** ，不会让单个桶中的数据超过 8 个，不过溢出桶只是 **`临时的解决方案`** ，创建过多的溢出桶最终也会导致哈希的扩容。

## 初始化

### 字面量初始化

```go
hash := map[string]string{
  "name": "zhangdeman",
  "university": "DLNU",
}
```

我们需要在初始化哈希时声明键值对的类型，这种使用字面量初始化的方式最终都会通过 **`src/cmd/compile/internal/gc/sinit.go@maplit`** 函数初始化，过程如下.go@maplit 函数初始化哈希的过程:

```go
func maplit(n *Node, m *Node, init *Nodes) {
  // make the map var
  a := nod(OMAKE, nil, nil)
  a.Esc = n.Esc
  a.List.Set2(typenod(n.Type), nodintconst(int64(n.List.Len())))
  litas(m, a, init)

  entries := n.List.Slice()

  // The order pass already removed any dynamic (runtime-computed) entries.
  // All remaining entries are static. Double-check that.
  for _, r := range entries {
    if !isStaticCompositeLiteral(r.Left) || !isStaticCompositeLiteral(r.Right) {
      Fatalf("maplit: entry is not a literal: %v", r)
    }
  }

  if len(entries) > 25 {
    // For a large number of entries, put them in an array and loop.

    // build types [count]Tindex and [count]Tvalue
    tk := types.NewArray(n.Type.Key(), int64(len(entries)))
    te := types.NewArray(n.Type.Elem(), int64(len(entries)))

    tk.SetNoalg(true)
    te.SetNoalg(true)

    dowidth(tk)
    dowidth(te)

    // make and initialize static arrays
    vstatk := readonlystaticname(tk)
    vstate := readonlystaticname(te)

    datak := nod(OARRAYLIT, nil, nil)
    datae := nod(OARRAYLIT, nil, nil)
    for _, r := range entries {
      datak.List.Append(r.Left)
      datae.List.Append(r.Right)
    }
    fixedlit(inInitFunction, initKindStatic, datak, vstatk, init)
    fixedlit(inInitFunction, initKindStatic, datae, vstate, init)

    // loop adding structure elements to map
    // for i = 0; i < len(vstatk); i++ {
    //  map[vstatk[i]] = vstate[i]
    // }
    i := temp(types.Types[TINT])
    rhs := nod(OINDEX, vstate, i)
    rhs.SetBounded(true)

    kidx := nod(OINDEX, vstatk, i)
    kidx.SetBounded(true)
    lhs := nod(OINDEX, m, kidx)

    zero := nod(OAS, i, nodintconst(0))
    cond := nod(OLT, i, nodintconst(tk.NumElem()))
    incr := nod(OAS, i, nod(OADD, i, nodintconst(1)))
    body := nod(OAS, lhs, rhs)

    loop := nod(OFOR, cond, incr)
    loop.Nbody.Set1(body)
    loop.Ninit.Set1(zero)

    loop = typecheck(loop, ctxStmt)
    loop = walkstmt(loop)
    init.Append(loop)
    return
  }
  // For a small number of entries, just add them directly.

  // Build list of var[c] = expr.
  // Use temporaries so that mapassign1 can have addressable key, elem.
  // TODO(josharian): avoid map key temporaries for mapfast_* assignments with literal keys.
  tmpkey := temp(m.Type.Key())
  tmpelem := temp(m.Type.Elem())

  for _, r := range entries {
    index, elem := r.Left, r.Right

    setlineno(index)
    a := nod(OAS, tmpkey, index)
    a = typecheck(a, ctxStmt)
    a = walkstmt(a)
    init.Append(a)

    setlineno(elem)
    a = nod(OAS, tmpelem, elem)
    a = typecheck(a, ctxStmt)
    a = walkstmt(a)
    init.Append(a)

    setlineno(tmpelem)
    a = nod(OAS, nod(OINDEX, m, tmpkey), tmpelem)
    a = typecheck(a, ctxStmt)
    a = walkstmt(a)
    init.Append(a)
  }

  a = nod(OVARKILL, tmpkey, nil)
  a = typecheck(a, ctxStmt)
  init.Append(a)
  a = nod(OVARKILL, tmpelem, nil)
  a = typecheck(a, ctxStmt)
  init.Append(a)
}
```

### 运行时

当创建的哈希被分配到栈上并且其 **`容量小于 BUCKETSIZE`** ，也就是 8 时，Go 语言在编译阶段会使用如下的方式快速初始化哈希，这也是编译器对容量下的哈希做的优化：

```go
var h *hmap
var hv hmap
var bv bmap
h := &hv
b := &bv
h.buckets = b
h.hash0 = fashtrand0()
```

除了上述特定的优化之外，无论 make 是从哪里来的，只要我们使用 make 创建哈希，Go 语言编译器都会在类型检查期间将它们转换成对  **`runtime.makemap`** 的调用，使用字面量来初始化哈希也只是语言提供的辅助工具，最后调用的都是 runtime.makemap ( **`src/runtime/map.go@makemap`** )

```go
// makemap implements Go map creation for make(map[k]v, hint).
// If the compiler has determined that the map or the first bucket
// can be created on the stack, h and/or bucket may be non-nil.
// If h != nil, the map can be created directly in h.
// If h.buckets != nil, bucket pointed to can be used as the first bucket.
func makemap(t *maptype, hint int, h *hmap) *hmap {
  mem, overflow := math.MulUintptr(uintptr(hint), t.bucket.size)
  if overflow || mem > maxAlloc {
    hint = 0
  }

  // initialize Hmap
  if h == nil {
    h = new(hmap)
  }
  h.hash0 = fastrand()

  // Find the size parameter B which will hold the requested # of elements.
  // For hint < 0 overLoadFactor returns false since hint < bucketCnt.
  B := uint8(0)
  for overLoadFactor(hint, B) {
    B++
  }
  h.B = B

  // allocate initial hash table
  // if B == 0, the buckets field is allocated lazily later (in mapassign)
  // If hint is large zeroing this memory could take a while.
  if h.B != 0 {
    var nextOverflow *bmap
    h.buckets, nextOverflow = makeBucketArray(t, h.B, nil)
    if nextOverflow != nil {
      h.extra = new(mapextra)
      h.extra.nextOverflow = nextOverflow
    }
  }

  return h
}
```

这个函数的执行过程会分成以下几个部分：

- 计算哈希占用的内存是否溢出或者超出能分配的最大值
- 调用 **`fastrand`** 获取一个随机的哈希种子
- 根据传入的 **`hint`** 计算出需要的最小需要的桶的数量
- 使用 **`runtime.makeBucketArray`** 创建用于保存桶的数组

**`runtime.makeBucketArray(src/runtime/map.go@makeBucketArray)`** 函数会根据传入的 B 计算出的需要创建的桶数量在内存中分配一片连续的空间用于存储数据.

```go
// makeBucketArray initializes a backing array for map buckets.
// 1<<b is the minimum number of buckets to allocate.
// dirtyalloc should either be nil or a bucket array previously
// allocated by makeBucketArray with the same t and b parameters.
// If dirtyalloc is nil a new backing array will be alloced and
// otherwise dirtyalloc will be cleared and reused as backing array.
func makeBucketArray(t *maptype, b uint8, dirtyalloc unsafe.Pointer) (buckets unsafe.Pointer, nextOverflow *bmap) {
  base := bucketShift(b)
  nbuckets := base
  // For small b, overflow buckets are unlikely.
  // Avoid the overhead of the calculation.
  if b >= 4 {
    // Add on the estimated number of overflow buckets
    // required to insert the median number of elements
    // used with this value of b.
    nbuckets += bucketShift(b - 4)
    sz := t.bucket.size * nbuckets
    up := roundupsize(sz)
    if up != sz {
      nbuckets = up / t.bucket.size
    }
  }

  if dirtyalloc == nil {
    buckets = newarray(t.bucket, int(nbuckets))
  } else {
    // dirtyalloc was previously generated by
    // the above newarray(t.bucket, int(nbuckets))
    // but may not be empty.
    buckets = dirtyalloc
    size := t.bucket.size * nbuckets
    if t.bucket.ptrdata != 0 {
      memclrHasPointers(buckets, size)
    } else {
      memclrNoHeapPointers(buckets, size)
    }
  }

  if base != nbuckets {
    // We preallocated some overflow buckets.
    // To keep the overhead of tracking these overflow buckets to a minimum,
    // we use the convention that if a preallocated overflow bucket's overflow
    // pointer is nil, then there are more available by bumping the pointer.
    // We need a safe non-nil pointer for the last overflow bucket; just use buckets.
    nextOverflow = (*bmap)(add(buckets, base*uintptr(t.bucketsize)))
    last := (*bmap)(add(buckets, (nbuckets-1)*uintptr(t.bucketsize)))
    last.setoverflow(t, (*bmap)(buckets))
  }
  return buckets, nextOverflow
}
```

当桶的数量小于 **`24`** 时，由于数据较少、使用溢出桶的可能性较低，这时就会省略创建的过程以减少额外开销；当桶的数量多于 24 时，就会额外创建 2𝐵−4 个溢出桶，根据上述代码，我们能确定在正常情况下，正常桶和溢出桶在内存中的存储空间是连续的，只是被 hmap 中的不同字段引用，当溢出桶数量较多时会通过 runtime.newobject(申请内存) 创建新的溢出桶。

## 数据读取

在编译的类型检查期间，hash[key] 以及类似的操作都会被转换成对哈希的 **`OINDEXMAP`** 操作，中间代码生成阶段会在 cmd/compile/internal/gc.walkexpr 函数中将这些 **`OINDEXMAP`** 操作转换成如下的代码:

```go
v     := hash[key] // => v     := *mapaccess1(maptype, hash, &key)
v, ok := hash[key] // => v, ok := mapaccess2(maptype, hash, &key)
```

赋值语句左侧接受参数的个数会决定使用的运行时方法：

- 当接受参数仅为一个时，会使用 runtime.mapaccess1，该函数仅会返回一个指向目标值的指针
- 当接受两个参数时，会使用 runtime.mapaccess2，除了返回目标值之外，它还会返回一个用于表示当前键对应的值是否存在的布尔值

runtime.mapaccess1( **`src/runtime/map.go@mapaccess1`** ) 函数会先通过哈希表设置的哈希函数、种子获取当前键对应的哈希，再通过 bucketMask 和 add 函数拿到该键值对所在的桶序号和哈希最上面的 8 位数字。

```go
// mapaccess1 returns a pointer to h[key].  Never returns nil, instead
// it will return a reference to the zero object for the elem type if
// the key is not in the map.
// NOTE: The returned pointer may keep the whole map live, so don't
// hold onto it for very long.
func mapaccess1(t *maptype, h *hmap, key unsafe.Pointer) unsafe.Pointer {
  if raceenabled && h != nil {
    callerpc := getcallerpc()
    pc := funcPC(mapaccess1)
    racereadpc(unsafe.Pointer(h), callerpc, pc)
    raceReadObjectPC(t.key, key, callerpc, pc)
  }
  if msanenabled && h != nil {
    msanread(key, t.key.size)
  }
  if h == nil || h.count == 0 {
    if t.hashMightPanic() {
      t.hasher(key, 0) // see issue 23734
    }
    return unsafe.Pointer(&zeroVal[0])
  }
  if h.flags&hashWriting != 0 {
    throw("concurrent map read and map write")
  }
  hash := t.hasher(key, uintptr(h.hash0))
  m := bucketMask(h.B)
  b := (*bmap)(add(h.buckets, (hash&m)*uintptr(t.bucketsize)))
  if c := h.oldbuckets; c != nil {
    if !h.sameSizeGrow() {
      // There used to be half as many buckets; mask down one more power of two.
      m >>= 1
    }
    oldb := (*bmap)(add(c, (hash&m)*uintptr(t.bucketsize)))
    if !evacuated(oldb) {
      b = oldb
    }
  }
  top := tophash(hash)
bucketloop:
  for ; b != nil; b = b.overflow(t) {
    for i := uintptr(0); i < bucketCnt; i++ {
      if b.tophash[i] != top {
        if b.tophash[i] == emptyRest {
          break bucketloop
        }
        continue
      }
      k := add(unsafe.Pointer(b), dataOffset+i*uintptr(t.keysize))
      if t.indirectkey() {
        k = *((*unsafe.Pointer)(k))
      }
      if t.key.equal(key, k) {
        e := add(unsafe.Pointer(b), dataOffset+bucketCnt*uintptr(t.keysize)+i*uintptr(t.elemsize))
        if t.indirectelem() {
          e = *((*unsafe.Pointer)(e))
        }
        return e
      }
    }
  }
  return unsafe.Pointer(&zeroVal[0])
}
```

在 bucketloop 循环中，哈希会 **`依次遍历正常桶和溢出桶`** 中的数据，它会比较这 8 位数字和桶中存储的 tophash，每一个桶都存储键对应的 tophash，每一次读写操作都会与桶中所有的 tophash 进行比较，用于选择桶序号的是哈希的 **`最低几位`** ，而用于加速访问的是哈希的 **`高 8 位`** ，这种设计能够减少同一个桶中有大量相等 tophash 的概率。

每一个桶都是一整片的内存空间，当发现桶中的 tophash 与传入键的 tophash 匹配之后，我们会通过指针和偏移量获取哈希中存储的键 keys[0] 并与 key 比较，如果两者相同就会获取目标值的指针 values[0] 并返回。

另一个同样用于访问哈希表中数据的 runtime.mapaccess2( **`src/runtime/map.go@mapaccess2`** ) 只是在 runtime.mapaccess1 的基础上多返回了一个标识键值对是否存在的布尔值

```go
func mapaccess2(t *maptype, h *hmap, key unsafe.Pointer) (unsafe.Pointer, bool) {
  if raceenabled && h != nil {
    callerpc := getcallerpc()
    pc := funcPC(mapaccess2)
    racereadpc(unsafe.Pointer(h), callerpc, pc)
  raceReadObjectPC(t.key, key, callerpc, pc)
  }
  if msanenabled && h != nil {
    msanread(key, t.key.size)
  }
  if h == nil || h.count == 0 {
    if t.hashMightPanic() {
      t.hasher(key, 0) // see issue 23734
    }
    return unsafe.Pointer(&zeroVal[0]), false
  }
  if h.flags&hashWriting != 0 {
    throw("concurrent map read and map write")
  }
  hash := t.hasher(key, uintptr(h.hash0))
  m := bucketMask(h.B)
  b := (*bmap)(unsafe.Pointer(uintptr(h.buckets) + (hash&m)*uintptr(t.bucketsize)))
  if c := h.oldbuckets; c != nil {
    if !h.sameSizeGrow() {
      // There used to be half as many buckets; mask down one more power of two.
      m >>= 1
    }
    oldb := (*bmap)(unsafe.Pointer(uintptr(c) + (hash&m)*uintptr(t.bucketsize)))
    if !evacuated(oldb) {
      b = oldb
    }
  }
  top := tophash(hash)
bucketloop:
  for ; b != nil; b = b.overflow(t) {
    for i := uintptr(0); i < bucketCnt; i++ {
      if b.tophash[i] != top {
        if b.tophash[i] == emptyRest {
          break bucketloop
        }
        continue
      }
      k := add(unsafe.Pointer(b), dataOffset+i*uintptr(t.keysize))
      if t.indirectkey() {
        k = *((*unsafe.Pointer)(k))
      }
      if t.key.equal(key, k) {
        e := add(unsafe.Pointer(b), dataOffset+bucketCnt*uintptr(t.keysize)+i*uintptr(t.elemsize))
        if t.indirectelem() {
          e = *((*unsafe.Pointer)(e))
        }
        return e, true
      }
    }
  }
  return unsafe.Pointer(&zeroVal[0]), false
}
```

使用 v, ok := hash[k] 的形式访问哈希表中元素时，我们能够通过这个布尔值更准确地知道当 v == nil 时，v 到底是哈希中存储的元素还是表示该键对应的元素不存在，所以在访问哈希时，更推荐使用这一种方式先判断元素是否存在。

## 数据写入

当形如 hash[k] 的表达式出现在赋值符号左侧时，该表达式也会在编译期间转换成调用 runtime.mapassign 函数，该函数与 runtime.mapaccess1 比较相似，我们将该其分成几个部分分析，首先是函数会根据传入的键拿到对应的哈希和桶

```go
func mapassign(t *maptype, h *hmap, key unsafe.Pointer) unsafe.Pointer {
  alg := t.key.alg
  hash := alg.hash(key, uintptr(h.hash0))

  h.flags ^= hashWriting

again:
  bucket := hash & bucketMask(h.B)
  b := (*bmap)(unsafe.Pointer(uintptr(h.buckets) + bucket*uintptr(t.bucketsize)))
  top := tophash(hash)
```

然后通过遍历比较桶中存储的 tophash 和键的哈希，如果找到了相同结果就会获取目标位置的地址并返回，其中 inserti 表示目标元素的在桶中的索引，insertk 和 val 分别表示键值对的地址，获得目标地址之后会直接通过算术计算进行寻址获得键值对 k 和 val：

```go
  var inserti *uint8
  var insertk unsafe.Pointer
  var val unsafe.Pointer
bucketloop:
  for {
    for i := uintptr(0); i < bucketCnt; i++ {
      if b.tophash[i] != top {
        if isEmpty(b.tophash[i]) && inserti == nil {
          inserti = &b.tophash[i]
          insertk = add(unsafe.Pointer(b), dataOffset+i*uintptr(t.keysize))
          val = add(unsafe.Pointer(b), dataOffset+bucketCnt*uintptr(t.keysize)+i*uintptr(t.valuesize))
        }
        if b.tophash[i] == emptyRest {
          break bucketloop
        }
        continue
      }
      k := add(unsafe.Pointer(b), dataOffset+i*uintptr(t.keysize))
      if !alg.equal(key, k) {
        continue
      }
      val = add(unsafe.Pointer(b), dataOffset+bucketCnt*uintptr(t.keysize)+i*uintptr(t.valuesize))
      goto done
    }
    ovf := b.overflow(t)
    if ovf == nil {
      break
    }
    b = ovf
  }
```

在上述的 for 循环中会依次遍历正常桶和溢出桶中存储的数据，整个过程会依次判断 tophash 是否相等、key 是否相等，遍历结束后会从循环中跳出。

如果当前桶已经满了，哈希会调用 **`newoverflow`** 函数创建新桶或者使用 hmap 预先在 noverflow 中创建好的桶来保存数据，新创建的桶不仅会被追加到已有桶的末尾，还会增加哈希表的 **`noverflow`** 计数器。

```go
  if inserti == nil {
    newb := h.newoverflow(t, b)
    inserti = &newb.tophash[0]
    insertk = add(unsafe.Pointer(newb), dataOffset)
    val = add(insertk, bucketCnt*uintptr(t.keysize))
  }

  typedmemmove(t.key, insertk, key)
  *inserti = top
  h.count++

done:
  return val
}
```

如果当前键值对在哈希中不存在，哈希为新键值对规划存储的内存地址，通过 typedmemmove 将键移动到对应的内存空间中并返回键对应值的地址 val，如果当前键值对在哈希中存在，那么就会直接返回目标区域的内存地址。哈希并不会在 mapassign 这个运行时函数中将值拷贝到桶中，该函数只会返回内存地址，真正的赋值操作是在编译期间插入的：

```go
00018 (+5) CALL runtime.mapassign_fast64(SB)
00020 (5) MOVQ 24(SP), DI               ;; DI = &value
00026 (5) LEAQ go.string."88"(SB), AX   ;; AX = &"88"
00027 (5) MOVQ AX, (DI)                 ;; *DI = AX
```

runtime.mapassign_fast64 与 runtime.mapassign 函数的实现差不多，我们需要关注的是后面的三行代码，24(SP) 就是该函数返回的值地址，我们通过 LEAQ 指令将字符串的地址存储到寄存器 AX 中，MOVQ 指令将字符串 "88" 存储到了目标地址上完成了这次哈希的写入。

## 哈希表扩容

runtime.mapassign 函数会在以下两种情况发生时触发哈希的扩容：

- 装载因子已经超过 **`6.5`**
- 哈希使用了 **`太多溢出桶`**

不过由于 Go 语言哈希的扩容 **`不是一个原子的过程`** ，所以 runtime.mapassign 函数还需要判断当前哈希是否已经处于扩容状态，避免二次扩容造成混乱。

```go
func mapassign(t *maptype, h *hmap, key unsafe.Pointer) unsafe.Pointer {
  //...
  if !h.growing() && (overLoadFactor(h.count+1, h.B) || tooManyOverflowBuckets(h.noverflow, h.B)) {
    hashGrow(t, h)
    goto again
  }
  //...
}
```

根据触发的条件不同扩容的方式分成两种

- 如果这次扩容是 **`溢出的桶太多`** 导致的，那么这次扩容就是 **`等量扩容 sameSizeGrow`** ，sameSizeGrow 是一种特殊情况下发生的扩容，当我们持续向哈希中插入数据并将它们全部删除时，如果哈希表中的数据量没有超过阈值，就会不断积累溢出桶造成 **`缓慢的内存泄漏`** 。[runtime: limit the number of map overflow buckets](https://github.com/golang/go/commit/9980b70cb460f27907a003674ab1b9bea24a847c) 引入了 sameSizeGrow 通过重用已有的哈希扩容机制，一旦哈希中出现了过多的溢出桶，它就会创建新桶保存数据，垃圾回收会清理老的溢出桶并释放内存。

扩容入口是( **`src/runtime/map.go@hashGrow`** )

```go
func hashGrow(t *maptype, h *hmap) {
  // If we've hit the load factor, get bigger.
  // Otherwise, there are too many overflow buckets,
  // so keep the same number of buckets and "grow" laterally.
  bigger := uint8(1)
  if !overLoadFactor(h.count+1, h.B) {
    bigger = 0
    h.flags |= sameSizeGrow
  }
  oldbuckets := h.buckets
  newbuckets, nextOverflow := makeBucketArray(t, h.B+bigger, nil)

  flags := h.flags &^ (iterator | oldIterator)
  if h.flags&iterator != 0 {
    flags |= oldIterator
  }
  // commit the grow (atomic wrt gc)
  h.B += bigger
  h.flags = flags
  h.oldbuckets = oldbuckets
  h.buckets = newbuckets
  h.nevacuate = 0
  h.noverflow = 0

  if h.extra != nil && h.extra.overflow != nil {
    // Promote current overflow buckets to the old generation.
    if h.extra.oldoverflow != nil {
      throw("oldoverflow is not nil")
    }
    h.extra.oldoverflow = h.extra.overflow
    h.extra.overflow = nil
  }
  if nextOverflow != nil {
    if h.extra == nil {
      h.extra = new(mapextra)
    }
    h.extra.nextOverflow = nextOverflow
  }

  // the actual copying of the hash table data is done incrementally
  // by growWork() and evacuate().
}
```

哈希在扩容的过程中会通过 runtime.makeBucketArray 创建一组新桶和预创建的溢出桶，随后将原有的桶数组设置到 oldbuckets 上并将新的空桶设置到 buckets 上，溢出桶也使用了相同的逻辑进行更新，下图展示了触发扩容后的哈希：

我们在 runtime.hashGrow 中还看不出来等量扩容和翻倍扩容的太多区别

- 等量扩容创建的新桶数量只是和旧桶一样，该函数中 **`只是创建了新的桶`** ，并 **`没有`** 对数据进行拷贝和转移，哈希表的数据迁移的过程在是 **`src/runtime/map.go@evacuate`** 函数中完成的，它会对传入桶中的元素进行 **`再分配`** 。

```go
func evacuate(t *maptype, h *hmap, oldbucket uintptr) {
  b := (*bmap)(add(h.oldbuckets, oldbucket*uintptr(t.bucketsize)))
  newbit := h.noldbuckets()
  if !evacuated(b) {
    // TODO: reuse overflow buckets instead of using new ones, if there
    // is no iterator using the old buckets.  (If !oldIterator.)

    // xy contains the x and y (low and high) evacuation destinations.
    var xy [2]evacDst
    x := &xy[0]
    x.b = (*bmap)(add(h.buckets, oldbucket*uintptr(t.bucketsize)))
    x.k = add(unsafe.Pointer(x.b), dataOffset)
    x.e = add(x.k, bucketCnt*uintptr(t.keysize))

    if !h.sameSizeGrow() {
      // Only calculate y pointers if we're growing bigger.
      // Otherwise GC can see bad pointers.
      y := &xy[1]
      y.b = (*bmap)(add(h.buckets, (oldbucket+newbit)*uintptr(t.bucketsize)))
      y.k = add(unsafe.Pointer(y.b), dataOffset)
      y.e = add(y.k, bucketCnt*uintptr(t.keysize))
    }

    for ; b != nil; b = b.overflow(t) {
      k := add(unsafe.Pointer(b), dataOffset)
      e := add(k, bucketCnt*uintptr(t.keysize))
      for i := 0; i < bucketCnt; i, k, e = i+1, add(k, uintptr(t.keysize)), add(e, uintptr(t.elemsize)) {
        top := b.tophash[i]
        if isEmpty(top) {
          b.tophash[i] = evacuatedEmpty
          continue
        }
        if top < minTopHash {
          throw("bad map state")
        }
        k2 := k
        if t.indirectkey() {
          k2 = *((*unsafe.Pointer)(k2))
        }
        var useY uint8
        if !h.sameSizeGrow() {
          // Compute hash to make our evacuation decision (whether we need
          // to send this key/elem to bucket x or bucket y).
          hash := t.hasher(k2, uintptr(h.hash0))
          if h.flags&iterator != 0 && !t.reflexivekey() && !t.key.equal(k2, k2) {
            // If key != key (NaNs), then the hash could be (and probably
            // will be) entirely different from the old hash. Moreover,
            // it isn't reproducible. Reproducibility is required in the
            // presence of iterators, as our evacuation decision must
            // match whatever decision the iterator made.
            // Fortunately, we have the freedom to send these keys either
            // way. Also, tophash is meaningless for these kinds of keys.
            // We let the low bit of tophash drive the evacuation decision.
            // We recompute a new random tophash for the next level so
            // these keys will get evenly distributed across all buckets
            // after multiple grows.
            useY = top & 1
            top = tophash(hash)
          } else {
            if hash&newbit != 0 {
              useY = 1
            }
          }
        }

        if evacuatedX+1 != evacuatedY || evacuatedX^1 != evacuatedY {
          throw("bad evacuatedN")
        }

        b.tophash[i] = evacuatedX + useY // evacuatedX + 1 == evacuatedY
        dst := &xy[useY]                 // evacuation destination

        if dst.i == bucketCnt {
          dst.b = h.newoverflow(t, dst.b)
          dst.i = 0
          dst.k = add(unsafe.Pointer(dst.b), dataOffset)
          dst.e = add(dst.k, bucketCnt*uintptr(t.keysize))
        }
        dst.b.tophash[dst.i&(bucketCnt-1)] = top // mask dst.i as an optimization, to avoid a bounds check
        if t.indirectkey() {
          *(*unsafe.Pointer)(dst.k) = k2 // copy pointer
        } else {
          typedmemmove(t.key, dst.k, k) // copy elem
        }
        if t.indirectelem() {
          *(*unsafe.Pointer)(dst.e) = *(*unsafe.Pointer)(e)
        } else {
          typedmemmove(t.elem, dst.e, e)
        }
        dst.i++
        // These updates might push these pointers past the end of the
        // key or elem arrays.  That's ok, as we have the overflow pointer
        // at the end of the bucket to protect against pointing past the
        // end of the bucket.
        dst.k = add(dst.k, uintptr(t.keysize))
        dst.e = add(dst.e, uintptr(t.elemsize))
      }
    }
    // Unlink the overflow buckets & clear key/elem to help GC.
    if h.flags&oldIterator == 0 && t.bucket.ptrdata != 0 {
      b := add(h.oldbuckets, oldbucket*uintptr(t.bucketsize))
      // Preserve b.tophash because the evacuation
      // state is maintained there.
      ptr := add(b, dataOffset)
      n := uintptr(t.bucketsize) - dataOffset
      memclrHasPointers(ptr, n)
    }
  }

  if oldbucket == h.nevacuate {
    advanceEvacuationMark(h, t, newbit)
  }
}
```

runtime.evacuate 函数会将一个 **`旧桶`** 中的数据分流到 **`两个新桶`** ，所以它会创建两个用于保存分配上下文的 evacDst 结构体，这两个结构体分别指向了一个新桶

如果这是一等量扩容，旧桶与新桶之间是一对一的关系，所以两个 evacDst 结构体只会初始化一个，当哈希表的容量翻倍时，每个旧桶的元素会都被分流到新创建的两个桶中

只使用哈希函数是不能定位到具体某一个桶的，哈希函数只会返回很长的哈希，例如：b72bfae3f3285244c4732ce457cca823bc189e0b，我们还需一些方法将哈希映射到具体的桶上，在很多时候我们都会使用取模或者位操作来获取桶的编号，假如当前哈希中包含 4 个桶，那么它的桶掩码就是 0b11(3)，使用位操作就会得到 3， 我们就会在 3 号桶中存储该数据

```go
0xb72bfae3f3285244c4732ce457cca823bc189e0b & 0b11 #=> 0
```

如果新的哈希表有 8 个桶，在大多数情况下，原来经过桶掩码 0b11 结果为 3 的数据会因为桶掩码增加了一位编程 0b111 而分流到新的 3 号和 7 号桶，所有数据也都会被 typedmemmove 拷贝到目标桶中

runtime.evacuate 最后会调用 runtime.advanceEvacuationMark  **`src/runtime/map.go@advanceEvacuationMark`**  增加哈希的 nevacuate 计数器，在所有的旧桶都被分流后清空哈希的 oldbuckets 和 oldoverflow 字段：

```go
func advanceEvacuationMark(h *hmap, t *maptype, newbit uintptr) {
  h.nevacuate++
  // Experiments suggest that 1024 is overkill by at least an order of magnitude.
  // Put it in there as a safeguard anyway, to ensure O(1) behavior.
  stop := h.nevacuate + 1024
  if stop > newbit {
    stop = newbit
  }
  for h.nevacuate != stop && bucketEvacuated(t, h, h.nevacuate) {
    h.nevacuate++
  }
  if h.nevacuate == newbit { // newbit == # of oldbuckets
    // Growing is all done. Free old main bucket array.
    h.oldbuckets = nil
    // Can discard old overflow buckets as well.
    // If they are still referenced by an iterator,
    // then the iterator holds a pointers to the slice.
    if h.extra != nil {
      h.extra.oldoverflow = nil
    }
    h.flags &^= sameSizeGrow
  }
}
```

之前在分析哈希表访问函数 runtime.mapaccess1 , 当哈希表的 oldbuckets 存在时，就会先定位到旧桶并在该桶没有被分流时从中获取键值对。

```go
func mapaccess1(t *maptype, h *hmap, key unsafe.Pointer) unsafe.Pointer {
  //...
  alg := t.key.alg
  hash := alg.hash(key, uintptr(h.hash0))
  m := bucketMask(h.B)
  b := (*bmap)(add(h.buckets, (hash&m)*uintptr(t.bucketsize)))
  if c := h.oldbuckets; c != nil {
    if !h.sameSizeGrow() {
      m >>= 1
    }
    oldb := (*bmap)(add(c, (hash&m)*uintptr(t.bucketsize)))
    if !evacuated(oldb) {
      b = oldb
    }
  }
bucketloop:
  //...
}
```

因为旧桶中还没有被 runtime.evacuate 函数分流，其中还保存着我们需要使用的数据，会替代新创建的空桶提供数据。

我们在 runtime.mapassign 函数中，当哈希表正在处于扩容状态时，每次向哈希表写入值时都会触发 runtime.growWork 对哈希表的内容进行增量拷贝

```go
func mapassign(t *maptype, h *hmap, key unsafe.Pointer) unsafe.Pointer {
  //...
again:
  bucket := hash & bucketMask(h.B)
  if h.growing() {
    growWork(t, h, bucket)
  }
  //...
}
```

当然除了写入操作之外，删除操作也会在哈希表扩容期间触发 runtime.growWork，触发的方式和代码与这里的逻辑几乎完全相同，都是计算当前值所在的桶，然后对该桶中的元素进行拷贝。

总结 : **`哈希表的扩容设计和原理`**

- 哈希在存储元素过多时会触发扩容操作
- 每次都会将桶的数量翻倍
- 整个扩容过程并不是原子的，而是通过 runtime.growWork 增量触发的
- 在扩容期间访问哈希表时会使用旧桶，向哈希表写入数据时会触发旧桶元素的分流
- 除了这种正常的扩容之外，为了解决大量写入、删除造成的内存泄漏问题，哈希引入了 **`sameSizeGrow`** 这一机制，在出现较多溢出桶时会对哈希进行 **`内存整理`** 减少对空间的占用。

## 数据删除

如果想要删除哈希中的元素，就需要使用 Go 语言中的 **`delete`** 关键字，这个关键字的唯一作用就是将某一个键对应的元素从哈希表中删除，无论是该键对应的值是否存在，这个内建的函数都 **`不会返回任何的结果`**

在编译期间，delete 关键字会被转换成操作为 **`ODELETE`** 的节点，而 ODELETE 会被 cmd/compile/internal/gc/walk.go@walkexpr 转换成 **`mapdelete`** 函数簇中的一个，包括 mapdelete、mapdelete_faststr、mapdelete_fast32 和 mapdelete_fast64

```go
func walkexpr(n *Node, init *Nodes) *Node {
  switch n.Op {
  case ODELETE:
    init.AppendNodes(&n.Ninit)
    map_ := n.List.First()
    key := n.List.Second()
    map_ = walkexpr(map_, init)
    key = walkexpr(key, init)

    t := map_.Type
    fast := mapfast(t)
    if fast == mapslow {
      key = nod(OADDR, key, nil)
    }
    n = mkcall1(mapfndel(mapdelete[fast], t), nil, init, typename(t), map_, key)
  }
}
```

这些函数的实现其实差不多，我们来分析其中的 runtime.mapdelete 函数，哈希表的删除逻辑与写入逻辑非常相似，只是触发哈希的删除需要使用关键字，如果在删除期间遇到了哈希表的扩容，就会对即将操作的桶进行分流，分流结束之后会找到桶中的目标元素完成键值对的删除工作。 实现如下( **`src/runtime/map.go@mapdelete`** )

```go
func mapdelete(t *maptype, h *hmap, key unsafe.Pointer) {
  if raceenabled && h != nil {
    callerpc := getcallerpc()
    pc := funcPC(mapdelete)
    racewritepc(unsafe.Pointer(h), callerpc, pc)
    raceReadObjectPC(t.key, key, callerpc, pc)
  }
  if msanenabled && h != nil {
    msanread(key, t.key.size)
  }
  if h == nil || h.count == 0 {
    if t.hashMightPanic() {
      t.hasher(key, 0) // see issue 23734
    }
    return
  }
  if h.flags&hashWriting != 0 {
    throw("concurrent map writes")
  }

  hash := t.hasher(key, uintptr(h.hash0))

  // Set hashWriting after calling t.hasher, since t.hasher may panic,
  // in which case we have not actually done a write (delete).
  h.flags ^= hashWriting

  bucket := hash & bucketMask(h.B)
  if h.growing() {
    growWork(t, h, bucket)
  }
  b := (*bmap)(add(h.buckets, bucket*uintptr(t.bucketsize)))
  bOrig := b
  top := tophash(hash)
search:
  for ; b != nil; b = b.overflow(t) {
    for i := uintptr(0); i < bucketCnt; i++ {
      if b.tophash[i] != top {
        if b.tophash[i] == emptyRest {
          break search
        }
        continue
      }
      k := add(unsafe.Pointer(b), dataOffset+i*uintptr(t.keysize))
      k2 := k
      if t.indirectkey() {
        k2 = *((*unsafe.Pointer)(k2))
      }
      if !t.key.equal(key, k2) {
        continue
      }
      // Only clear key if there are pointers in it.
      if t.indirectkey() {
        *(*unsafe.Pointer)(k) = nil
      } else if t.key.ptrdata != 0 {
        memclrHasPointers(k, t.key.size)
      }
      e := add(unsafe.Pointer(b), dataOffset+bucketCnt*uintptr(t.keysize)+i*uintptr(t.elemsize))
      if t.indirectelem() {
        *(*unsafe.Pointer)(e) = nil
        } else if t.elem.ptrdata != 0 {
        memclrHasPointers(e, t.elem.size)
      } else {
        memclrNoHeapPointers(e, t.elem.size)
      }
      b.tophash[i] = emptyOne
      // If the bucket now ends in a bunch of emptyOne states,
      // change those to emptyRest states.
      // It would be nice to make this a separate function, but
      // for loops are not currently inlineable.
      if i == bucketCnt-1 {
        if b.overflow(t) != nil && b.overflow(t).tophash[0] != emptyRest {
          goto notLast
        }
      } else {
        if b.tophash[i+1] != emptyRest {
          goto notLast
        }
      }
      for {
        b.tophash[i] = emptyRest
        if i == 0 {
          if b == bOrig {
            break // beginning of initial bucket, we're done.
          }
          // Find previous bucket, continue at its last entry.
          c := b
          for b = bOrig; b.overflow(t) != c; b = b.overflow(t) {
          }
          i = bucketCnt - 1
        } else {
          i--
        }
        if b.tophash[i] != emptyOne {
          break
        }
      }
    notLast:
      h.count--
      // Reset the hash seed to make it more difficult for attackers to
      // repeatedly trigger hash collisions. See issue 25237.
      if h.count == 0 {
        h.hash0 = fastrand()
      }
      break search
    }
  }

  if h.flags&hashWriting == 0 {
    throw("concurrent map writes")
  }
  h.flags &^= hashWriting
}
```

只需要知道 delete 关键字在编译期间经过类型检查和中间代码生成阶段被转换成 runtime.mapdelete 函数簇中的一员就可以，用于处理删除逻辑的函数与哈希表的 runtime.mapassign 几乎完全相同，不太需要刻意关注.

## 总结

- Go 语言使用 **`拉链法`** 来解决哈希碰撞的问题实现了哈希表，它的访问、写入和删除等操作都在编译期间转换成了 **`运行时的函数或者方法`**
- 哈希在每一个桶中存储键对应哈希的前 8 位，当对哈希进行操作时，这些 tophash 就成为了 **`一级缓存`** 帮助哈希快速遍历桶中元素，每一个桶都只能存储 **`8 个`** 键值对，一旦当前哈希的某个桶超出 8 个，新的键值对就会被存储到哈希的 **`溢出桶`** 中。
- 随着键值对数量的增加，溢出桶的数量和哈希的 **`装载因子`** 也会逐渐升高，超过一定范围就会触发扩容，扩容会将 **`桶的数量翻倍`** ，元素再分配的过程也是在调用写操作时增量进行的，不会造成性能的瞬时巨大抖动。
