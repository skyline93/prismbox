（完整整理版，已补充缺失关键点，适用于 60 / 120 FPS 架构级标准）

---

## 前言：目标与方法论

本文目标只有一个：

> **在真实业务复杂度下，稳定跑满 60 / 120 FPS，并且在低端 Android 设备上仍具备可接受的体感。**

Flutter 性能优化不是“技巧合集”，而是一套**可推导、可验证、可复用的工程方法论**。

核心闭环只有四步：

> **测量 → 定位 → 优化 → 验证**

本文从 Flutter 引擎渲染的 **五个核心阶段**（Build / Layout / Paint / Compositing / Rasterizing）出发，并从 **Widget 树 → Element 树 → RenderObject / Layer 树** 的传导关系进行全链路拆解。

---

## 第一部分：渲染管线五阶段的系统级优化

---

## 一、Build 阶段：最小化 CPU 构建压力

Build 阶段的本质是：

> **Widget → Element 的 Diff 与更新**

性能问题的根源几乎都来自：**无效 rebuild 范围过大**。

---

### 1. 精准切片状态依赖（InheritedWidget / Provider）

#### 问题本质
- `Provider.of<T>(context)` 会让整个 Widget 订阅 T
- T 任意字段变化 → 当前 Element 标记 dirty

#### 架构级解法
```dart
context.select<T, R>((t) => t.someField);
```

**原理**：
- 为 `R` 建立独立依赖
- 仅当 `someField` 变化时才 rebuild

#### 架构建议
- 状态结构尽量扁平
- 避免深层嵌套对象（`==` 比较成本高）

---

### 2. 严格保持 `build()` 的纯度

#### 硬性红线
- `build()` 可能 1 秒执行 120 次
- **禁止在 build 中做任何计算、分配、IO、正则**

#### 正确做法
```dart
static const boxDecoration = BoxDecoration(...);
```

**原因**：
- 高频对象分配 → GC 抖动 → 微卡顿（Stutter）

---

### 3. Key 的战略部署

#### 使用场景
- 列表顺序变化
- 动态插入 / 删除

#### 原理
Key 帮助 Diff 算法精准复用 Element / State，避免 Inflate

#### 警告
- `GlobalKey` 会强制全树重新布局
- **除 Hero / 跨树复用，严禁滥用**

---

## 二、Layout 阶段：避免布局击穿（Layout Thrashing）

Layout 遵循：

> **Constraints Down → Size Up**

错误布局会导致 O(N²) 复杂度。

---

### 1. 全面禁止 Intrinsic 系列组件

#### 问题
- `IntrinsicHeight / Width` = 预布局 + 正式布局

#### 架构替代
- `CustomMultiChildLayout`
- 在 delegate 中直接给尺寸

---

### 2. Relayout Boundary（布局边界）

#### 原理
- 尺寸变化是否向父级回溯

#### 实践
- List item 提供明确约束
- 避免无约束 Column 嵌套

---

## 三、Painting / Compositing：GPU 成本控制

**体感卡顿 80% 来自这里。**

---

### 1. RepaintBoundary 的正确使用

#### 作用
- 创建独立 Layer
- 局部重绘，不波及整树

#### 重要补充：Layer 数量红线

> **Layer 数量 > 100 时，需高度警惕合成开销**

**经验法则**：
- 大静态 + 小动态：切
- 大量小组件频繁动：不切

---

### 2. 离屏渲染（saveLayer）的代价

#### 高危组件
- Opacity（非 0/1）
- ClipRRect
- ShaderMask
- ColorFilter

#### 原理
- GPU 创建临时缓冲区 → 像素混合 → 写回

#### 替代策略
- 圆角：BoxDecoration
- 透明：ARGB / 贴图

---

### 3. Canvas / Path 的隐藏杀手

#### 问题
- 超大 / 复杂 Path
- 高频 `drawShadow`

#### 优化
- Path → Picture 缓存
- 或直接位图资源

---

## 四、Rasterizing 阶段：低端设备的生死线

#### 识别方式
- Performance Overlay Raster 红

#### 常见原因
- 超大图片
- 多层透明
- 复杂 Clip

---

## 第二部分：线程与异步架构

---

## 五、Threading：让主线程只做 UI

---

### 1. Isolate 线程池

#### 使用时机
- JSON > 5MB
- 图像 / 元数据解析

#### 关键优化
- `TransferableTypedData`
- 所有权转移，避免拷贝

---

### 2. Microtask 使用边界

#### 正确场景
- 当前帧结束后执行一次逻辑

#### 红线
- 禁止循环
- 禁止重逻辑

---

## 第三部分：资源与内存管理

---

## 六、图片与内存控制

---

### 1. 图片下采样（强制）

```dart
Image.network(
  url,
  cacheWidth: (screenWidth * devicePixelRatio).toInt(),
)
```

#### 内存公式
- RGBA = 宽 × 高 × 4 字节

---

### 2. Shader 预热

#### 方案
- 新项目：Impeller
- 老项目：SkSL 预埋

---

## 第四部分：Widget 树视角的系统级优化

---

## 七、Widget 树 = 蓝图系统

> **Widget 变化 ≠ 渲染变化**

目标：

> **让 Widget 变化对 Element / RenderObject 影响最小**

---

### 1. 扁平化与原子化

- 避免深层嵌套
- 使用 Class Widget，而非函数

---

### 2. const 的短路效应

- const Widget = 内存唯一引用
- `oldWidget == newWidget` → 子树直接跳过

---

### 3. child 预载模式

```dart
AnimatedBuilder(
  animation: controller,
  child: const HeavyWidget(),
  builder: (_, child) => Transform.rotate(
    angle: controller.value,
    child: child,
  ),
);
```

---

### 4. 状态的物理隔离

> **setState 会让整个子树参与 Diff**

#### 架构原则
- 高频状态 → 最小 StatefulWidget
- 页面状态 → 低频

---

### 5. 滚动性能的致命陷阱

❌ 错误：
```dart
controller.addListener(() {
  setState(() {});
});
```

✅ 正确：
- AnimatedBuilder
- SliverPersistentHeaderDelegate

> **滚动逻辑禁止直接 setState**

---

### 6. Sliver 体系

> **任何 >50 item 的复杂列表，应使用 Sliver 建模**

#### 优势
- 按需布局
- 按需绘制
- 内存可控

---

### 7. Visibility / Offstage 策略

- 高频切换：Offstage
- 低频切换：条件渲染

---

## 第五部分：性能排查与工具链

---

## 八、架构师必备工具

1. Performance Overlay
2. DevTools Timeline
3. SkSL Trace
4. Dump Render Tree（Layer 数量）

---

## 最终性能红线 Checklist

| 模块 | 必做 | 红线 |
|----|----|----|
| Build | const / select | build 中逻辑 |
| Layout | 明确约束 | Intrinsic |
| Paint | 局部 Repaint | saveLayer 滥用 |
| Raster | 小图 | 原图缩略 |
| Scroll | Sliver | setState |
| State | 隔离 | 页面级高频状态 |

---

## 架构师最终总结

> **Flutter 的性能优化，本质是控制“变化的传播范围”。**

当你能做到：
- Widget 静态
- 状态精准
- GPU 负担可控

那么：

> **1000 个 Widget，也能稳定 120 FPS。**

