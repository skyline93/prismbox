# Change: 移动端 lib 目录结构整改（按优先级分阶段）

## Why

当前 `mobile/lib` 存在多处与 `openspec/project.md` 目录结构规范不一致或规范未覆盖的情况，导致：

- **lib/widgets/** 游离在规范之外（规范要求组件在 `presentation/widgets/<feature>/` 或 `common/`），影响心智一致性和后续重构。
- **favorite_indicator** 实际路径为 `presentation/widgets/media/`，而 `openspec/specs/timeline-page/spec.md` 要求位于 `presentation/widgets/timeline/`，与 spec 冲突。
- **project.md** 仅明确写出 `presentation/` 与 `providers/`，未文档化 `data/`、`domain/`、`services/`、`features/`、`core/`、`infrastructure/`、`config/`、`utils/`、`platform/` 的职责与边界，易导致新代码放置随意。
- **Providers** 分散在 `lib/providers/`、`lib/services/*/providers/`、`lib/features/*/providers/` 三处，与「按 feature 在 providers/ 组织」的约定不一致。

本变更通过分阶段（高/中/低优先级）整改，使目录与规范对齐并补全文档，便于后续维护和重构。

## What Changes

- **高优先级**
  - 将 **lib/widgets/**（含 photo_view、photo_view_gallery 及 widgets/src/ 子结构）迁移至 **lib/presentation/widgets/common/**（或等价子目录），统一所有 `package:prismbox/widgets/` 的 import 为新路径；删除顶层 `lib/widgets/`。
  - 统一 **favorite_indicator** 与 timeline-page spec：要么将组件移至 `lib/presentation/widgets/timeline/favorite_indicator.dart` 并更新引用，要么修改 spec 明确允许放在 `media/` 并说明原因；二选一并在文档中固定。
- **中优先级**
  - 在 **openspec/project.md**（或项目内单一权威文档）中补全 **mobile lib 完整目录规范**：明确 `data/`、`domain/`、`services/`、`features/`、`core/`、`infrastructure/`、`config/`、`utils/`、`platform/` 的职责与推荐子结构。
  - 明确 **config/** 与 **core/config/** 的边界；若决定统一，则将 `lib/config/` 收敛到 `lib/core/config/`（或反之文档化分工）。
  - **lib/presentation/widgets/common/ 按当前目录结构规范处理**：去除 `common/src/` 及其中按 controller/core/utils 的层级，将实现文件打平至 `common/` 下；文件名采用与 project 一致的命名（功能前缀 + snake_case，如 `photo_view_controller.dart`）；更新所有对 `presentation/widgets/common/src/` 的 import；在 project.md 中明确 common 下禁止使用 `src/`、与 feature 一致采用扁平结构及功能前缀命名。
- **中低优先级**
  - 制定并文档化 **Provider 放置策略**（顶层 `providers/<feature>/` vs feature 内 `providers/`），并逐步将对外暴露的、页面/组件直接使用的 Provider 定义收拢到选定位置；或明确允许 feature 内聚并统一命名/导出方式。
  - 将 **utils/** 中与某 feature 强相关的工具迁入对应 feature 或 presentation，避免 `utils/` 成为杂项筐（可选、按需执行）。
- **规范与 spec**
  - 新增能力 **mobile-directory-structure**：在 `openspec/specs/mobile-directory-structure/spec.md` 中增加「组件禁止顶层 widgets」「favorite_indicator 路径与 spec 一致」「完整目录职责说明」「Provider 放置策略」等可验证需求。
  - 必要时对 **timeline-page** spec 中 favorite_indicator 路径做 MODIFIED delta（若选择改 spec 而非改代码路径）。

## Impact

- **Affected specs**: 新增 `mobile-directory-structure`；可能 MODIFIED `timeline-page`（favorite_indicator 路径）。
- **Affected code**: `mobile/lib/` 目录结构、大量 import 路径（widgets 迁移、common 打平后 import 更新）、零散文件移动（favorite_indicator、config 收敛等）；`openspec/project.md` 及可选单页「mobile 目录说明」文档。
- **Breaking**: 所有引用 `package:prismbox/widgets/` 的 Dart 文件需更新 import；若移动 favorite_indicator，引用该组件的文件需更新；common 打平后，所有引用 `presentation/widgets/common/src/` 的文件需更新为新路径。
- **Non-breaking**: 文档与 spec 补全、Provider 策略文档化与渐进迁移、utils 整理均为可增量进行。
