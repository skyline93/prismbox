# language Specification

## Purpose
定义 AI 生成和修改内容时使用的语言规范，确保所有文档、注释、错误信息等使用中文，同时保持代码标识符（类名、方法名、变量名）使用英文。

## Requirements

### Requirement: 必须使用中文

所有由 AI 生成或修改的内容 SHALL 使用中文。

#### Scenario: 文档内容使用中文
- **WHEN** AI 生成或修改 spec 文档
- **THEN** 文档内容必须使用中文
- **AND** change / task 文档必须使用中文

#### Scenario: 代码注释使用中文
- **WHEN** AI 生成或修改代码注释
- **THEN** 注释（/// 或 //）必须使用中文

#### Scenario: 错误和日志信息使用中文
- **WHEN** AI 生成错误信息或日志信息
- **THEN** 错误信息、日志信息必须使用中文

#### Scenario: README 文档使用中文
- **WHEN** AI 生成或修改 README 相关说明
- **THEN** README 文档内容必须使用中文

### Requirement: 禁止英文说明

AI 生成的内容 SHALL 不得输出英文说明，专有名词除外。

#### Scenario: 禁止英文说明
- **WHEN** AI 生成内容
- **THEN** 不得输出英文说明（专有名词除外）
- **AND** 不得中英混用

### Requirement: 代码标识符保持英文

代码中的类名、方法名、变量名 SHALL 保持英文，符合编程语言规范。

#### Scenario: 代码关键字和标识符
- **WHEN** AI 生成代码
- **THEN** Dart / Flutter 代码关键字保持英文
- **AND** 类名、方法名、变量名保持英文
