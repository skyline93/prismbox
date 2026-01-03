## MODIFIED Requirements

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

#### Scenario: 清理废弃代码
- **WHEN** 代码库中存在废弃的功能模块或代码
- **THEN** 系统 SHALL 及时清理废弃代码，移除未使用的文件、导入和依赖
- **AND** 清理过程 SHALL 确保不影响现有功能
- **AND** 清理后 SHALL 验证代码编译通过且无残留引用

