# Design: 移动端 lib 目录结构整改

## Context

- **openspec/project.md** 当前仅规定：`lib/presentation/`（pages、widgets、routing）与 `lib/providers/`，且要求「拆分出来的组件」位于 `presentation/widgets/<feature>/` 或 `presentation/widgets/common/`。
- 实际 **mobile/lib** 存在顶层 `widgets/`、`data/`、`domain/`、`services/`、`features/`、`core/`、`infrastructure/`、`config/`、`utils/`、`platform/` 等，其中 `widgets/` 与规范直接冲突，其余未在规范中说明。
- Providers 分布在 `providers/`、`services/*/providers/`、`features/*/providers/`，缺少统一策略。
- **configuration-management** spec 已约定：编译时配置在 `lib/config/app_config.dart`，运行时系统配置在 `lib/core/config/`，用户设置在 `lib/core/settings/app_setting.dart`。故 `config/` 与 `core/config/` 的边界已有部分定义，需在目录规范中显式写出，避免混淆。

## Goals / Non-Goals

- **Goals**
  - 消除顶层 `lib/widgets/`，所有 UI 组件归属 `presentation/widgets/`。
  - 统一 favorite_indicator 路径与 timeline-page spec（代码或 spec 二选一）。
  - 在 project.md 或等效文档中补全 lib 各顶层目录的职责与推荐子结构。
  - 明确 config 与 core/config 的边界；明确 Provider 放置策略并文档化。
- **Non-Goals**
  - 不在本变更中强制迁移所有 feature 内 providers 到顶层（可渐进）；不强制重写所有历史代码的 import 风格（仅对本次迁移的 widgets 与明确移动的文件更新 import）。

## Decisions

### 1. 顶层 widgets 迁移目标

- **Decision**：将 `lib/widgets/` 整体迁移至 `lib/presentation/widgets/common/` 下，保留内部子结构（如 `common/photo_view/` 或 `common/photo_view/src/`），对外 import 统一为 `package:prismbox/presentation/widgets/common/...`。
- **Alternatives**：迁入 `presentation/widgets/viewer/`（仅适用于 viewer 相关）。选择 common 更符合「跨 feature 公用组件」的既有规范表述。
- **Rationale**：与 project.md 中「widgets 仅在 presentation/widgets 下」一致，且 common 已约定为跨 feature 公用组件。

### 2. favorite_indicator 路径

- **Decision**：由实现阶段决定二选一：(A) 将实现移至 `lib/presentation/widgets/timeline/favorite_indicator.dart` 并更新引用，保持与 timeline-page spec 一致；或 (B) 修改 timeline-page spec，明确允许组件位于 `lib/presentation/widgets/media/favorite_indicator.dart` 并说明「媒体与时间线共用，以 media 为准」。
- **Recommendation**：若组件仅在时间线/媒体网格等同一类上下文中使用，迁至 timeline 更符合「按 feature 放组件」；若多处独立使用，保留 media 并改 spec 更合理。
- **Rationale**：避免 spec 与实现长期不一致，导致后续重构或审查时混淆。

### 3. 完整目录规范写入位置

- **Decision**：在 **openspec/project.md** 的「移动端」章节下扩展「目录结构规范」小节，增加完整 lib 树状说明（data、domain、services、features、core、infrastructure、config、utils、platform），与现有 presentation、providers 并列；不单独新建「mobile 目录说明」页，除非后续文档体积过大再拆。
- **Rationale**：单一真相来源，减少多文档不同步；project.md 已是 AI 与开发者的首要上下文。

### 4. config/ 与 core/config/ 边界

- **Decision**：与 configuration-management spec 对齐：**lib/config/** 仅保留「编译时/应用入口级」配置（如 `app_config.dart`）；**lib/core/config/** 存放「运行时系统配置」及 ConfigRegistry 相关类型（如 NetworkConfig、TaskConfig、SyncConfig、CacheConfig）。不在本变更中强制移动现有 `lib/config/` 文件，但文档中明确上述边界，新代码按此放置。
- **Rationale**：configuration-management 已约定三层配置与 core/config 的用途，此处仅文档化目录边界，避免冲突。

### 5. Provider 放置策略

- **Decision**：采用**双轨策略并文档化**：(1) **对外/页面级使用的 Provider 定义** 推荐放在 `lib/providers/<feature>/`，便于发现与复用；(2) **仅 feature 内部使用、与 feature 强绑定的 Provider** 可保留在 `lib/features/<name>/providers/`，但需在 project.md 中写明「feature 内 providers 仅限本 feature 使用，跨 feature 需置于 lib/providers/」。不强制在本变更中迁移现有 features 内 providers，后续按需逐步收拢。
- **Rationale**：平衡「按 feature 发现」与「避免 providers 目录膨胀」；明确规则后新代码有据可依。

### 6. 新增能力 mobile-directory-structure

- **Decision**：新增 OpenSpec 能力 **mobile-directory-structure**，其 spec 包含：禁止顶层 lib/widgets、favorite_indicator 路径与 spec 一致、完整目录职责说明、Provider 放置策略等可验证需求；本 change 通过 ADDED 方式贡献该能力的首版 requirements。
- **Rationale**：目录规范可被自动化或人工检查引用，与现有 timeline-page、media-viewer 等 spec 中的路径要求一致。

### 7. common/ 内部结构规范

- **Decision**：`lib/presentation/widgets/common/` 下 SHALL 不使用 `src/` 子目录；所有公用组件的实现文件 SHALL 与 feature 目录一致，采用**扁平结构**置于 `common/` 下，文件名使用**功能前缀 + snake_case**（如 `photo_view_controller.dart`、`photo_view_core.dart`），与 project.md 中「新组件文件名必须包含功能前缀」一致。迁移时将现有 `common/src/`（含 controller/、core/、utils/）内文件移入 `common/`，按需重命名为带 `photo_view_` 前缀，并更新所有 import。
- **Alternatives**：保留 src/ 作为「实现隐藏」——在单包应用内 project 未约定 src 语义，且其他 feature 均为扁平，保留会与规范不一致。
- **Rationale**：与 project 目录规范及 UI 命名规范统一，避免 common 成为例外；减少层级便于查找与审查。

## Risks / Trade-offs

- **Import 批量修改**：widgets 迁移会导致所有 `package:prismbox/widgets/` 的 import 变更，存在遗漏或复制粘贴错误风险。缓解：全局搜索替换 + 静态分析/编译通过 + 单测或冒烟测试。
- **Provider 双轨策略**：长期可能出现「部分人放 providers/、部分人放 features/」的不一致。缓解：在 project.md 与 code review 中明确规则，并在 mobile-directory-structure spec 中写成可检查的 Requirement。

## Migration Plan

- **Phase 1（高优先级）**：迁移 lib/widgets → presentation/widgets/common；统一 favorite_indicator 路径或 spec；更新所有受影响 import；删除 lib/widgets。
- **Phase 2（中优先级）**：在 project.md 中补全 lib 目录树与职责；明确 config 与 core/config 边界；**将 common/ 打平（去除 src/，统一命名）并更新 import**；在 project.md 中明确 common 内部结构规范；可选地收敛 config 下文件到 core/config。
- **Phase 3（中低优先级）**：在 project.md 与 mobile-directory-structure spec 中写入 Provider 策略；按需迁移或标记现有 features 内 providers；可选整理 utils。
- **Rollback**：每阶段可独立回滚（如 widgets 迁移可通过 git revert 或再次移动目录还原）；文档与 spec 变更无运行时影响，回滚仅恢复旧文档即可。

## Open Questions

- 无阻塞问题。favorite_indicator 的最终路径（timeline vs media）由实现时根据使用范围决定即可。
