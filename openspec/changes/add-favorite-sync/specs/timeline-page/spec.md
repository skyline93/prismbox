## ADDED Requirements

### Requirement: 收藏图标展示

时间线页面的资产缩略图 SHALL 在左下角显示收藏图标，用于指示资产是否被标记为收藏。收藏图标 SHALL 仅在资产的 isFavorite 属性为 true 时显示。

#### Scenario: 收藏图标组件定义

- **WHEN** 定义收藏图标组件（FavoriteIndicator）
- **THEN** 组件 SHALL 位于 lib/presentation/widgets/timeline/favorite_indicator.dart
- **AND** 组件类名 SHALL 为 FavoriteIndicator
- **AND** 组件 SHALL 使用 StatelessWidget
- **AND** 组件 SHALL 提供 const 构造函数
- **AND** 组件 SHALL 接收 isFavorite 布尔参数

#### Scenario: 收藏图标仅在收藏时显示

- **WHEN** 资产的 isFavorite 属性为 true
- **THEN** 系统 SHALL 在缩略图左下角显示心形图标
- **AND** 心形图标 SHALL 使用填充样式（实心）
- **AND** 心形图标颜色 SHALL 为白色或红色
- **WHEN** 资产的 isFavorite 属性为 false
- **THEN** 系统 SHALL 不显示收藏图标

#### Scenario: 收藏图标视觉样式

- **WHEN** 显示收藏图标
- **THEN** 图标 SHALL 位于缩略图的左下角
- **AND** 图标大小 SHALL 为 16-20 像素
- **AND** 图标 SHALL 有半透明黑色圆形背景（opacity 0.5-0.7）
- **AND** 图标距离左边缘 SHALL 为 4-8 像素
- **AND** 图标距离底边缘 SHALL 为 4-8 像素
- **AND** 图标背景 SHALL 提供足够对比度，确保在任何照片背景下可见

#### Scenario: 集成到时间线缩略图

- **WHEN** 渲染时间线中的资产缩略图
- **THEN** 缩略图 SHALL 使用 Stack 布局容器
- **AND** FavoriteIndicator 组件 SHALL 作为 Stack 的子组件
- **AND** FavoriteIndicator SHALL 位于 Stack 的顶层（不被其他元素遮挡）
- **AND** FavoriteIndicator SHALL 接收 asset.isFavorite 作为参数
- **AND** 其他 UI 元素（如选择框、视频时长标识）SHALL 不与收藏图标重叠

#### Scenario: 组件性能要求

- **WHEN** 使用 FavoriteIndicator 组件
- **THEN** 组件 SHALL 提供 const 构造函数
- **AND** 组件 SHALL 避免不必要的重建
- **AND** 组件 SHALL 使用 const 定义静态图标和样式
- **AND** 组件渲染 SHALL 不影响时间线滚动性能

#### Scenario: 收藏图标在选择模式下的显示

- **WHEN** 时间线进入选择模式
- **THEN** 收藏图标 SHALL 继续显示
- **AND** 收藏图标 SHALL 不影响选择框的显示和交互
- **AND** 收藏图标的层级 SHALL 低于选择框

#### Scenario: 收藏状态更新后的 UI 刷新

- **WHEN** 资产的收藏状态在本地数据库中更新
- **THEN** 时间线 UI SHALL 自动刷新显示最新状态
- **AND** 如果收藏状态从 false 变为 true，SHALL 显示收藏图标
- **AND** 如果收藏状态从 true 变为 false，SHALL 隐藏收藏图标

