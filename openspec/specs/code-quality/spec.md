# code-quality Specification

## Purpose
定义 AI 生成代码的质量标准，确保所有生成的代码符合编译、静态分析和最佳实践要求，避免伪代码、占位符、臆造 API 等问题。

## Requirements

### Requirement: 通用编码约束

所有 AI 生成的代码 SHALL 满足通用编码约束，确保代码质量和可维护性。

#### Scenario: 禁止伪代码和占位符
- **WHEN** AI 生成代码
- **THEN** 不允许使用伪代码、占位函数、TODO、未实现逻辑
- **AND** 所有函数、方法必须返回完整、确定的返回值

#### Scenario: 禁止臆造 API
- **WHEN** AI 生成代码
- **THEN** 不允许臆造类型、方法、字段、第三方库 API
- **AND** 所有引用的变量、函数、类、依赖必须真实存在

#### Scenario: 禁止假设隐式上下文
- **WHEN** AI 生成代码
- **THEN** 不允许假设隐式上下文（如"已存在某对象 / Provider / Service"）
- **AND** 所有依赖必须显式声明和初始化

#### Scenario: 编译前自检
- **WHEN** AI 输出代码前
- **THEN** 必须从编译器 / 静态分析器视角完成自检
- **AND** 仅输出最终可编译 / 可 analyze 的代码

### Requirement: 开发阶段错误处理策略（FAIL-FAST）

**项目当前处于开发阶段，未上线**。所有代码 SHALL 采用 FAIL-FAST（快速失败）策略，遇到错误必须立即抛出异常并崩溃，禁止静默处理、降级处理或吞掉错误。

#### Scenario: 禁止静默错误处理
- **WHEN** 代码中遇到任何错误、异常或失败情况
- **THEN** 必须立即抛出异常（throw/rethrow/panic），禁止使用 try-catch 吞掉错误
- **AND** 禁止使用 `catch (e) { /* 空处理或仅记录日志 */ }` 的静默处理模式
- **AND** 禁止使用 `catch (e) { continue; }` 或 `catch (e) { return; }` 等跳过错误的模式
- **AND** 禁止在 catch 块中仅记录警告日志后继续执行

#### Scenario: 禁止降级处理
- **WHEN** 操作失败时
- **THEN** 禁止使用默认值、空值、占位符作为降级方案
- **AND** 禁止使用重试机制掩盖错误（除非是明确的网络重试，且最终失败必须抛出）
- **AND** 禁止使用备用路径（fallback）来绕过错误

#### Scenario: 数据库操作失败必须崩溃
- **WHEN** 数据库操作失败（插入、更新、删除、查询）
- **THEN** 必须直接抛出异常，禁止使用 upsert 或 insertOrUpdate 等降级操作
- **AND** 如果批量操作失败，必须抛出异常，禁止逐个重试
- **AND** 唯一约束冲突、外键约束冲突等数据库错误必须抛出，禁止静默转换为更新操作

#### Scenario: 网络请求失败必须崩溃
- **WHEN** 网络请求失败（超时、连接错误、服务器错误）
- **THEN** 必须抛出异常，禁止使用默认响应或空数据
- **AND** 禁止在网络错误时返回空列表、空对象作为默认值
- **AND** 禁止在网络错误时使用缓存数据作为降级方案（除非明确是缓存策略）

#### Scenario: 文件操作失败必须崩溃
- **WHEN** 文件读写操作失败
- **THEN** 必须抛出异常，禁止创建空文件或返回空数据
- **AND** 禁止在文件不存在时创建占位文件
- **AND** 禁止在文件损坏时返回默认内容

#### Scenario: 业务逻辑错误必须崩溃
- **WHEN** 业务逻辑校验失败（数据不合法、状态不正确、权限不足）
- **THEN** 必须抛出异常，禁止使用默认值或跳过验证
- **AND** 禁止在验证失败时返回默认对象或空对象

#### Scenario: 允许的错误处理场景
- **WHEN** 错误需要向上层传播时
- **THEN** 允许捕获错误后重新包装并抛出（rethrow with context）
- **AND** 允许在 UI 层捕获错误并显示给用户，但底层服务层必须抛出异常
- **AND** 允许在测试代码中使用 try-catch 进行断言

#### Scenario: 错误日志记录要求
- **WHEN** 抛出异常前
- **THEN** 必须记录详细的错误日志（包含堆栈跟踪）
- **AND** 日志级别必须使用 ERROR 或 SEVERE，禁止使用 WARNING
- **AND** 日志必须包含足够的上下文信息（参数值、状态信息等）

### Requirement: Golang 编码约束

所有 Go 代码 SHALL 通过编译和静态分析检查，符合 Go 语言最佳实践。

#### Scenario: Go 代码必须通过标准检查
- **WHEN** 生成 Go 代码
- **THEN** 代码必须通过 `go vet`、`go test ./...`、`go build ./...`
- **AND** 不允许出现未使用的变量或 import
- **AND** 不允许出现未导入但使用的包
- **AND** 不允许出现编译期错误（类型不匹配、接口未实现）

#### Scenario: 类型和接口定义
- **WHEN** 定义 Go 类型
- **THEN** 所有 `struct`、`interface` 必须显式定义，禁止匿名结构体滥用
- **AND** 所有接口实现必须完整，不允许遗漏方法

#### Scenario: 错误处理
- **WHEN** 编写 Go 代码
- **THEN** 所有错误必须显式处理，不允许忽略 `error` 返回值
- **AND** 不允许出现可能导致编译期 panic 的写法（如明显的 nil 解引用）
- **AND** 在开发阶段，所有错误必须直接返回或使用 `panic()`，禁止使用默认值或空值作为降级
- **AND** 禁止使用 `if err != nil { log.Warn(...); continue }` 等静默处理模式
- **AND** 数据库操作失败必须返回错误，禁止使用事务回滚后继续执行

#### Scenario: 并发安全
- **WHEN** 使用并发特性
- **THEN** goroutine / channel 必须保证类型安全与可控生命周期

### Requirement: Flutter / Dart 编码约束

所有 Dart / Flutter 代码 SHALL 通过静态分析和测试，符合 Dart 语言和 Flutter 框架最佳实践。

#### Scenario: Dart 代码必须通过标准检查
- **WHEN** 生成 Dart / Flutter 代码
- **THEN** 代码必须通过 `dart analyze`、`flutter analyze`、`flutter test`（如涉及测试）
- **AND** 不允许出现未使用的 import、变量、参数、字段
- **AND** 不允许出现未声明或未初始化即使用的变量

#### Scenario: Null Safety 约束
- **WHEN** 编写 Dart 代码
- **THEN** 严格遵守 Null Safety（NNBD）
- **AND** 不允许忽略空安全
- **AND** 禁止无理由使用 `!`
- **AND** 禁止使用 `dynamic`，除非有明确说明且无法替代

#### Scenario: Widget 定义规范
- **WHEN** 创建 Widget
- **THEN** 所有 Widget 必须明确继承 `StatelessWidget` 或 `StatefulWidget`
- **AND** 必须正确实现 `build(BuildContext context)` 方法

#### Scenario: StatefulWidget 生命周期
- **WHEN** 使用 StatefulWidget
- **THEN** 必须正确绑定 `State<T>`
- **AND** 不在 `build` 方法中执行副作用逻辑（网络、IO、初始化）

#### Scenario: 控制器资源管理
- **WHEN** 使用控制器（TextEditingController、AnimationController 等）
- **THEN** 不得在 `build` 中创建控制器
- **AND** 必须在 `dispose()` 中释放控制器

#### Scenario: 异步代码处理
- **WHEN** 编写异步代码
- **THEN** 必须使用 `async / await`
- **AND** 必须正确处理 `Future`，不允许悬空调用
- **AND** 在开发阶段，所有 `Future` 错误必须通过 `throw` 抛出，禁止使用 `.catchError()` 吞掉错误
- **AND** 禁止使用 `try-catch` 捕获异常后仅记录日志而不重新抛出

#### Scenario: 第三方依赖管理
- **WHEN** 使用第三方依赖
- **THEN** 依赖必须在 `pubspec.yaml` 中声明
- **AND** 必须使用真实存在的 API

### Requirement: AI 输出前自检流程

AI 在输出代码前 SHALL 完成自检流程，确保代码质量。

#### Scenario: 模拟执行检查
- **WHEN** AI 输出代码前
- **THEN** 必须模拟执行编译/分析命令
- **AND** Go 代码：执行 `go build`
- **AND** Flutter/Dart 代码：执行 `flutter analyze`

#### Scenario: 类型和依赖检查
- **WHEN** AI 完成代码生成
- **THEN** 必须检查类型匹配
- **AND** 必须检查 import / dependency 完整性
- **AND** 必须检查空安全与生命周期问题

#### Scenario: 问题修正
- **WHEN** 发现任何问题
- **THEN** 必须先修正问题，再输出代码
- **AND** 禁止输出中间推导、分析过程或草稿代码

#### Scenario: 错误处理策略检查
- **WHEN** AI 生成包含错误处理的代码
- **THEN** 必须检查是否符合 FAIL-FAST 策略
- **AND** 必须识别并移除所有静默错误处理（空 catch 块、仅记录日志的 catch、降级处理）
- **AND** 必须确保所有错误都直接抛出异常
- **AND** 必须验证数据库操作失败会抛出异常，而不是使用 upsert 降级

### Requirement: OpenSpec 提案任务范围规范

OpenSpec 提案的 `tasks.md` SHALL 只包含可以通过代码变更完成的任务，排除运行时测试、手动验证等不在代码实现范围内的任务。

#### Scenario: 应该包含的任务类型
- **WHEN** 创建 OpenSpec 提案的 `tasks.md`
- **THEN** 必须包含以下类型的任务：
  - 代码实现任务（创建文件、实现类、编写函数等）
  - 代码重构任务（重构方法、提取组件、优化结构等）
  - 代码更新任务（更新导入路径、修改调用方式、适配新接口等）
  - 代码删除任务（删除旧文件、移除废弃代码等）
  - 代码质量检查任务（运行 linter、静态分析、编译检查等）
  - 单元测试编写任务（编写测试代码、添加测试用例等）
  - 代码文档更新任务（更新注释、添加文档字符串等）
  - 配置文件更新任务（更新依赖、修改配置等）

#### Scenario: 不应该包含的任务类型
- **WHEN** 创建 OpenSpec 提案的 `tasks.md`
- **THEN** 必须排除以下类型的任务：
  - 运行时手动测试任务（如"运行应用，测试功能是否正常工作"）
  - 手动验证场景任务（如"测试所有错误场景"）
  - 手动功能验证任务（如"验证加密空间相关功能正常工作"）
  - 用户验收测试任务（如"验证用户体验是否流畅"）
  - 性能测试任务（如"测试应用性能是否满足要求"）
  - 集成测试任务（如"测试与其他模块的集成"）
  - 部署验证任务（如"验证部署后功能正常"）

#### Scenario: 任务分类原则
- **WHEN** 判断任务是否应该包含在 `tasks.md` 中
- **THEN** 使用以下原则判断：
  - 如果任务可以通过编写、修改或删除代码完成，则应该包含
  - 如果任务需要运行应用、手动操作或人工验证，则不应该包含
  - 如果任务可以通过自动化工具验证（如 linter、静态分析），则应该包含
  - 如果任务需要人工判断或主观评估，则不应该包含

#### Scenario: 代码质量检查任务的边界
- **WHEN** 包含代码质量检查任务
- **THEN** 只包含可以通过工具自动检查的任务：
  - 运行 `flutter analyze`、`go vet` 等静态分析工具
  - 运行 `dart format`、`gofmt` 等代码格式化工具
  - 运行编译检查（`flutter build`、`go build`）
  - 运行单元测试（`flutter test`、`go test`）
- **AND** 不包含需要人工判断的任务：
  - 代码风格的主观评估
  - 性能优化的效果验证
  - 用户体验的主观评价

#### Scenario: 测试任务的边界
- **WHEN** 包含测试相关任务
- **THEN** 只包含编写测试代码的任务：
  - 创建测试文件
  - 编写测试用例
  - 实现测试辅助函数
- **AND** 不包含执行测试的任务：
  - 运行测试并验证结果
  - 手动测试特定场景
  - 验证测试覆盖率

#### Scenario: 文档任务的边界
- **WHEN** 包含文档相关任务
- **THEN** 只包含可以通过代码变更完成的文档任务：
  - 更新代码注释
  - 添加文档字符串
  - 更新 README 文件
  - 更新 API 文档
- **AND** 不包含需要人工编写的文档任务：
  - 编写用户手册
  - 编写架构设计文档（除非是代码生成）
  - 编写使用教程
