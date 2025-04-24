---
layout: default
title: Benchmarks
nav_order: 4
---

## Hashids performance comparison

EncodedId uses a custom `HashId` implementation that is optimized for both speed and memory usage, significantly outperforming the original `hashids` gem (which is now unsupported).

### Benchmarks

Recent benchmarks show significant improvements:

```
| Test                      | Hashids (i/s) | EncodedId::HashId (i/s) | Speedup |
| ------------------------- | ------------ | --------------------- | ------- |
| #encode - 1 ID            |  131,000.979 |           197,586.231 |   1.51x |
| #decode - 1 ID            |   65,791.334 |            92,425.571 |   1.40x |
| #encode - 10 IDs          |   13,773.355 |            20,669.715 |   1.50x |
| #decode - 10 IDs          |    6,911.872 |             9,990.078 |   1.45x |
| #encode w YJIT - 1 ID     |  265,764.969 |           877,551.362 |   3.30x |
| #decode w YJIT - 1 ID     |  130,154.837 |           348,000.817 |   2.67x |
| #encode w YJIT - 10 IDs   |   27,966.457 |           100,461.237 |   3.59x |
| #decode w YJIT - 10 IDs   |   14,187.346 |            43,974.011 |   3.10x |
| #encode w YJIT - 1000 IDs |      268.140 |             1,077.855 |   4.02x |
| #decode w YJIT - 1000 IDs |      136.217 |               464.579 |   3.41x |
```

With YJIT enabled, performance improvements are even more significant, with up to 4x faster operation for large inputs.

### Memory Usage

Memory usage is also dramatically improved:

```
| Test                | Implementation   | Allocated Memory | Allocated Objects | Memory Reduction |
| ------------------- | ---------------- | ---------------- | ----------------- | ---------------- |
| encode small input  | Hashids          |          7.28 KB |               120 |                - |
|                     | EncodedId::HashId |            920 B |                 6 |           87.66% |
| encode large input  | Hashids          |        403.36 KB |              5998 |                - |
|                     | EncodedId::HashId |          8.36 KB |               104 |           97.93% |
| decode large input  | Hashids          |        366.88 KB |              5761 |                - |
|                     | EncodedId::HashId |         14.63 KB |               264 |           96.01% |
```

The memory usage improvements are dramatic, with up to 98% reduction in memory allocation for large inputs.
