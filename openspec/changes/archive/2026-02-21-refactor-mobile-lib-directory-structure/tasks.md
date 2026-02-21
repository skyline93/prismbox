# Tasks: 移动端 lib 目录结构整改

## 1. 高优先级：消除游离 widgets 与统一 favorite_indicator

- [x] 1.1 将 `mobile/lib/widgets/` 整目录迁移至 `mobile/lib/presentation/widgets/common/`（保留内部子结构，如 `common/photo_view/` 或 `common/photo_view/src/`）
- [x] 1.2 全局替换 import：`package:prismbox/widgets/` → `package:prismbox/presentation/widgets/common/`（或等价子路径），确保所有引用文件更新
- [x] 1.3 删除已迁移的顶层 `mobile/lib/widgets/` 目录
- [x] 1.4 运行 `dart analyze` 与构建，确认无残留 `package:prismbox/widgets/` 引用且编译通过
- [x] 1.5 决定 favorite_indicator 路径策略：(A) 将组件移至 `lib/presentation/widgets/timeline/favorite_indicator.dart` 并更新引用，或 (B) 修改 `openspec/specs/timeline-page/spec.md` 明确允许 `lib/presentation/widgets/media/favorite_indicator.dart` 并说明原因
- [x] 1.6 执行 1.5 所选方案（移动文件或修改 spec），若移动则更新所有引用并验证

## 2. 中优先级：补全目录规范与 config 边界

- [x] 2.1 在 `openspec/project.md` 的移动端「目录结构规范」小节中，补全完整 lib 树状结构：`data/`、`domain/`、`services/`、`features/`、`core/`、`infrastructure/`、`config/`、`utils/`、`platform/` 的职责与推荐子目录
- [x] 2.2 在 project.md 中明确 `config/` 与 `core/config/` 的边界（编译时/入口配置 vs 运行时系统配置），与 configuration-management spec 对齐
- [x] 2.3 若决定将现有 `lib/config/` 下内容收敛到 `lib/core/config/`，执行迁移并更新 import；否则仅在文档中注明边界，新代码按边界放置
- [x] 2.4 将 `mobile/lib/presentation/widgets/common/src/` 下所有文件移入 `common/`，去除 `src/` 及其中 `controller/`、`core/`、`utils/` 子目录；文件名统一为带 `photo_view_` 前缀的 snake_case（如 `photo_view_controller.dart`、`photo_view_core.dart`、`photo_view_utils.dart`），与 project 命名规范一致
- [x] 2.5 更新 `common/` 内所有相互引用及项目内引用 `presentation/widgets/common/src/` 的 import 路径为新扁平路径
- [x] 2.6 在 project.md 的「目录结构规范」中补充：`presentation/widgets/common/` 下禁止使用 `src/`，与 feature 一致采用扁平结构，文件名使用功能前缀 + snake_case
- [x] 2.7 运行 `dart analyze` 与构建，确认 common 打平后无残留 `common/src/` 引用且编译通过

## 3. 中低优先级：Provider 策略与可选整理

- [x] 3.1 在 project.md 中新增「Provider 放置策略」：对外/页面级 Provider 置于 `lib/providers/<feature>/`；feature 内仅自用的可置于 `lib/features/<name>/providers/`，并注明跨 feature 需使用 `lib/providers/`
- [x] 3.2 在 `openspec/specs/mobile-directory-structure/spec.md` 中落实与 Provider 策略、目录职责对应的可验证 Requirement（见本 change 的 spec delta）
- [x] 3.3 （可选）将 `lib/utils/` 中与某 feature 强相关的工具迁入对应 feature 或 presentation，并更新引用
- [ ] 3.4 （可选）按需将现有 `features/*/providers/` 或 `services/*/providers/` 中对外暴露的 Provider 定义迁移至 `lib/providers/<feature>/`，并更新引用（已分析；迁移涉及 build_runner 与大量引用，留待后续按需执行）

## 4. 规范与校验

- [ ] 4.1 归档本 change 时，将 `openspec/changes/refactor-mobile-lib-directory-structure/specs/mobile-directory-structure/spec.md` 的 ADDED 内容合并至 `openspec/specs/mobile-directory-structure/spec.md`（新建能力）
- [ ] 4.2 若 1.5 选择修改 timeline-page spec，归档时合并 timeline-page 的 spec delta 至 `openspec/specs/timeline-page/spec.md`
- [x] 4.3 运行 `openspec validate --strict` 确认变更与 spec 一致
