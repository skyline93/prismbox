## ADDED Requirements

### Requirement: 禁止顶层 widgets 目录

移动端 `mobile/lib` 下 SHALL 不存在顶层目录 `widgets/`。所有可复用的 UI 组件（含图片查看、画廊等公用组件）SHALL 位于 `lib/presentation/widgets/<feature>/` 或 `lib/presentation/widgets/common/` 下。

#### Scenario: 无顶层 widgets
- **WHEN** 检查 `mobile/lib` 的顶层目录
- **THEN** 不存在 `lib/widgets/` 目录
- **AND** 所有原属于顶层 widgets 的组件 SHALL 已迁移至 `lib/presentation/widgets/common/` 或相应 feature 子目录

#### Scenario: 组件引用路径统一
- **WHEN** 代码中引用图片查看或画廊等原 widgets 包内的组件
- **THEN** import 路径 SHALL 使用 `package:prismbox/presentation/widgets/common/...`（或等价子路径）
- **AND** 禁止使用 `package:prismbox/widgets/` 作为 import 前缀

### Requirement: favorite_indicator 路径与 spec 一致

收藏图标组件（FavoriteIndicator）的路径 SHALL 与 `openspec/specs/timeline-page/spec.md` 中「收藏图标组件定义」Scenario 所规定的路径一致；若项目选择将组件置于 media 而非 timeline，则 timeline-page spec 中该 Scenario SHALL 已修改为明确允许 `lib/presentation/widgets/media/favorite_indicator.dart` 并说明原因。

#### Scenario: 路径与 spec 一致
- **WHEN** 查看 timeline-page spec 中关于 FavoriteIndicator 组件路径的 Scenario
- **THEN** 实际实现文件路径 SHALL 与 spec 中规定路径一致
- **AND** 若规定为 `lib/presentation/widgets/timeline/favorite_indicator.dart`，则实现 SHALL 位于该路径
- **AND** 若规定为允许 `lib/presentation/widgets/media/favorite_indicator.dart`，则 spec 中 SHALL 已明确写出该路径及原因（如「媒体与时间线共用，以 media 为准」）

### Requirement: 完整 lib 目录职责文档化

项目 SHALL 在 `openspec/project.md`（或项目内单一权威文档）的移动端目录结构规范中，对 `mobile/lib` 以下顶层目录的职责与推荐子结构做出说明：`presentation/`、`providers/`、`data/`、`domain/`、`services/`、`features/`、`core/`、`infrastructure/`、`config/`、`utils/`、`platform/`。

#### Scenario: 各目录职责可查
- **WHEN** 查阅 project.md 中移动端目录结构规范
- **THEN** 存在对 `data/`（数据层：数据库表、DAO、枚举、部分 models）的说明
- **AND** 存在对 `domain/`（领域实体与仓储接口）的说明
- **AND** 存在对 `services/`（业务服务，按 feature 分子目录）的说明
- **AND** 存在对 `features/`（功能模块聚合）的说明
- **AND** 存在对 `core/`（存储、配置、缓存、设置等基础设施）的说明
- **AND** 存在对 `infrastructure/`（API 客户端、网络、平台实现）的说明
- **AND** 存在对 `config/` 与 `core/config/` 的边界说明（编译时/入口配置 vs 运行时系统配置）

#### Scenario: config 与 core/config 边界明确
- **WHEN** 需要放置新的配置类或配置文件
- **THEN** 文档中 SHALL 明确：`lib/config/` 仅用于编译时/应用入口级配置（如 app_config.dart）
- **AND** `lib/core/config/` 用于运行时系统配置及 ConfigRegistry 相关类型
- **AND** 与 capability configuration-management 的约定一致

### Requirement: Provider 放置策略

项目 SHALL 在目录结构规范中规定 Riverpod Provider 的放置策略：对外或页面级使用的 Provider 定义推荐置于 `lib/providers/<feature>/`；仅 feature 内部使用的 Provider 可置于 `lib/features/<name>/providers/`，且跨 feature 使用时 SHALL 使用或迁移至 `lib/providers/`。

#### Scenario: 策略文档化
- **WHEN** 查阅 project.md 中移动端目录或 Provider 相关规范
- **THEN** 存在「Provider 放置策略」说明
- **AND** 说明中 SHALL 规定 `lib/providers/<feature>/` 用于对外/页面级 Provider
- **AND** 说明中 SHALL 规定 feature 内 `providers/` 仅限本 feature 使用，跨 feature 需置于 `lib/providers/`

#### Scenario: 新代码可依策略放置
- **WHEN** 新增跨 feature 使用的 Provider
- **THEN** 该 Provider 定义 SHALL 置于 `lib/providers/<feature>/` 下
- **AND** 禁止在未文档化例外的情况下将跨 feature Provider 仅放在 `lib/features/*/providers/` 或 `lib/services/*/providers/` 且无对应 `lib/providers/` 导出

### Requirement: common 目录内部结构规范

`lib/presentation/widgets/common/` 下 SHALL 不使用 `src/` 子目录；公用组件的实现文件 SHALL 与 feature 目录一致，采用扁平结构置于 `common/` 下，文件名使用功能前缀 + snake_case（与 project.md UI 命名规范一致）。

#### Scenario: common 下无 src
- **WHEN** 检查 `mobile/lib/presentation/widgets/common/` 的目录结构
- **THEN** 不存在 `common/src/` 目录
- **AND** 所有原位于 `common/src/` 下的实现文件 SHALL 已移入 `common/` 且 import 已更新

#### Scenario: common 内文件命名与规范一致
- **WHEN** 在 `presentation/widgets/common/` 下新增或审视文件
- **THEN** 文件名 SHALL 使用功能前缀 + snake_case（如 `photo_view_controller.dart`、`photo_view_core.dart`）
- **AND** 与 project.md 中「新组件文件名必须包含功能前缀」的约定一致
- **AND** 禁止使用 `package:prismbox/presentation/widgets/common/src/` 作为 import 前缀
