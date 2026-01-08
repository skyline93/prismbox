（架构师实战版，可直接用于团队规范 / 评审 / 复盘）

---

# 第一部分：10 条 Flutter 性能铁律（Performance Commandments）

> **目标一句话**：任何一个页面，只要遵守这 10 条，大概率可以稳定 60 FPS；严格执行，在绝大多数设备上可冲 120 FPS。

---

## 铁律 1：一切优化，从 Performance Overlay 开始

* UI 红 → Build / Isolate / 主线程
* Raster 红 → GPU / saveLayer / 图片 / Clip

❗ **不看 Overlay 就优化 = 盲修**

---

## 铁律 2：build() 里只允许“声明”，禁止“计算”

* build 可能 1 秒跑 120 次
* 任何 new / 逻辑 / 正则 / JSON 解析都是罪

✅ static const
❌ build 中 new 对象

---

## 铁律 3：能 const 的 Widget，一个都不能少

* const = 引用唯一
* oldWidget == newWidget → 子树直接跳过

👉 **const 是 Flutter 最便宜、收益最高的优化**

---

## 铁律 4：状态变化必须“切片”，禁止整树污染

* Provider.of / watch 是粗斧头
* select / Builder 是手术刀

👉 **状态订阅范围 ≤ 实际使用范围**

---

## 铁律 5：setState 的作用域，必须小到“刚刚好”

* setState 会让整个子树参与 Diff

✅ 高频状态 → 最小 StatefulWidget
❌ 页面级 setState 扛动画 / 滚动

---

## 铁律 6：滚动相关逻辑，永远禁止直接 setState

❌ ScrollController.addListener + setState

✅ AnimatedBuilder
✅ SliverPersistentHeaderDelegate

> **滚动 = 每帧触发，犯错必掉帧**

---

## 铁律 7：超过 50 个复杂 item，必须使用 Sliver 体系

* Sliver = 按需布局 + 按需绘制
* ListView / GridView 只是语法糖

👉 **大列表不卡，靠的是 Sliver，不是运气**

---

## 铁律 8：RepaintBoundary 是“手术刀”，不是“止血贴”

* 每个 RepaintBoundary = 一个 Layer

⚠️ **Layer 数量 > 100 = 合成风险区**

---

## 铁律 9：saveLayer 是 GPU 杀手，能不用就不用

高危组件：

* Opacity (非 0/1)
* ClipRRect
* ShaderMask

👉 优先 BoxDecoration / 贴图方案

---

## 铁律 10：任何图片，必须按显示尺寸解码

* 原图解码 = 内存 + Raster 双杀

✅ cacheWidth / cacheHeight
❌ 原图当缩略图

---

# 第二部分：真实掉帧案例 → 铁律反向映射

> **用途**：性能事故复盘 / 新人培训 / 架构评审

---

## 案例 1：列表滑动卡顿，但 Build 很快

### 现象

* UI 线程绿
* Raster 线程红

### 定位

* 列表 item 内大量 ClipRRect + Opacity

### 命中铁律

* ❌ 铁律 9：saveLayer 滥用

### 修复方案

* ClipRRect → BoxDecoration
* 移除不必要透明

---

## 案例 2：页面无动画，但偶发微卡

### 现象

* Timeline 出现 GC spikes

### 定位

* build 中 new BoxDecoration / TextStyle

### 命中铁律

* ❌ 铁律 2 / 3

### 修复方案

* static const

---

## 案例 3：Tab 切换流畅，滚动时掉帧

### 现象

* 滚动即掉帧

### 定位

```dart
controller.addListener(() {
  setState(() {});
});
```

### 命中铁律

* ❌ 铁律 6

### 修复方案

* AnimatedBuilder
* SliverPersistentHeader

---

## 案例 4：大列表首滑卡顿

### 现象

* 首次滚动明显卡

### 定位

* 非 Sliver ListView
* item 动态高度

### 命中铁律

* ❌ 铁律 7

### 修复方案

* SliverList
* SliverFixedExtentList

---

## 案例 5：动画区域很小，但整页重绘

### 现象

* 小动画导致整屏 Raster 红

### 定位

* 未设置 RepaintBoundary

### 命中铁律

* ❌ 铁律 8

---

## 案例 6：Riverpod AsyncNotifier 一直处于 loading 状态

### 现象

* Provider 状态一直停留在 loading
* `load()` 方法被调用但请求未发出
* 后端没有收到 API 请求

### 定位

```dart
@override
Future<List<Post>> build(String groupUuid) async {
  // ❌ 错误：直接返回同步值
  return [];
}

Future<void> load() async {
  // ❌ 错误：build() 返回的 Future 让状态变为 loading
  // 此时检查 state.isLoading 为 true，直接返回
  if (state.isLoading) return;
  // ...
}
```

### 命中问题

* ❌ Riverpod AsyncNotifier `build()` 方法未使用 `Future.value()`
* ❌ 时序问题：`build()` 完成后立即调用 `load()` 被误判

### 修复方案

```dart
@override
Future<List<Post>> build(String groupUuid) async {
  // ✅ 正确：使用 Future.value() 确保立即完成
  return Future.value([]);
}
```

### 参考文档

* 详见：`mobile/doc/riverpod-asyncnotifier-best-practices.md`

---

# 第三部分：Flutter 性能 Code Review Checklist

> **使用方式**：
>
> * PR 必查
> * 性能评审必勾
> * 新功能上线前过一遍

---

## 一、Build 阶段（CPU）

* [ ] build 方法中是否 **零逻辑 / 零 new 对象**
* [ ] 所有可能的 Widget 是否已使用 const
* [ ] 是否避免函数返回 Widget（优先 Class）

---

## 二、状态管理

* [ ] 状态订阅是否使用 select / 局部 Builder
* [ ] 是否存在页面级 setState 承载高频变化
* [ ] 高频状态是否已物理隔离

### Riverpod AsyncNotifier 专项检查

* [ ] `build()` 方法是否使用 `Future.value()` 返回初始值（避免状态停留在 loading）
* [ ] `build()` 方法是否只负责初始化，不执行数据加载
* [ ] 数据加载是否在单独的 `load()`、`refresh()` 等方法中
* [ ] `load()` 方法的状态检查是否考虑了 `build()` 初始化的场景
* [ ] 是否存在时序问题：`build()` 完成后立即调用 `load()` 是否会被误判为"已在加载中"

---

## 三、列表 / 滚动

* [ ] 是否使用 Sliver 构建复杂列表
* [ ] 是否为 item 提供确定尺寸 / 约束
* [ ] 是否存在 Scroll + setState

---

## 四、绘制 / GPU

* [ ] 是否存在不必要的 Opacity / ClipRRect
* [ ] RepaintBoundary 是否只用于“必要隔离”
* [ ] Layer 数量是否可控（非滥用）

---

## 五、图片 / 资源

* [ ] 所有图片是否设置 cacheWidth / Height
* [ ] 是否避免原图直接显示

---

## 六、线程 / 异步

* [ ] 大 JSON / 重计算是否进入 Isolate
* [ ] 是否避免 Microtask 中执行重逻辑

---

## 结语（给架构师的一句话）

> **Flutter 性能优化不是“把代码写复杂”，而是“把变化关在笼子里”。**

当你能做到：

* 变化可控
* 影响可测
* 成本可预期

那么性能就不再是玄学，而是工程能力。
