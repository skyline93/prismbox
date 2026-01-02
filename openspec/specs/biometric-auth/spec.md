# biometric-auth Specification

## Purpose
TBD - created by archiving change extract-biometric-service. Update Purpose after archive.
## Requirements
### Requirement: 生物识别设备支持检测
系统 SHALL 提供检测设备是否支持生物识别认证的能力。

#### Scenario: 检查设备支持
- **WHEN** 应用检查设备是否支持生物识别认证
- **THEN** 如果设备支持生物识别认证（指纹、面部识别等），系统返回 `true`，否则返回 `false`

#### Scenario: 处理不支持的设备
- **WHEN** 应用在没有生物识别硬件的设备上检查生物识别支持
- **THEN** 系统返回 `false`，不抛出异常

### Requirement: 生物识别可用性检查
系统 SHALL 提供检查设备上是否有可用且已配置的生物识别认证方法的能力。

#### Scenario: 检查生物识别可用性
- **WHEN** 应用检查是否有可用的生物识别方法
- **THEN** 如果至少有一种生物识别方法可用且已配置，系统返回 `true`，否则返回 `false`

#### Scenario: 处理未配置的生物识别
- **WHEN** 设备支持生物识别但未配置任何方法
- **THEN** 系统返回 `false`

### Requirement: 可用生物识别类型查询
系统 SHALL 提供查询设备上可用生物识别类型列表的能力。

#### Scenario: 获取可用生物识别类型
- **WHEN** 应用查询可用的生物识别类型
- **THEN** 系统返回可用生物识别类型列表（例如：指纹、面部、虹膜）

#### Scenario: 处理无可用生物识别类型
- **WHEN** 没有可用的生物识别类型
- **THEN** 系统返回空列表

### Requirement: 生物识别认证执行
系统 SHALL 提供执行生物识别认证的能力，支持自定义原因消息和配置选项。

#### Scenario: 认证成功
- **WHEN** 用户成功完成生物识别认证（指纹、面部等）
- **THEN** 系统返回 `BiometricAuthResult`，其中 `success = true`，并包含用于认证的 `biometricType`

#### Scenario: 认证失败 - 错误的生物识别
- **WHEN** 用户生物识别认证失败（错误的指纹、面部未识别等）
- **THEN** 系统返回 `BiometricAuthResult`，其中 `success = false` 且 `failure = BiometricAuthFailure.authenticationFailed`

#### Scenario: 认证取消
- **WHEN** 用户取消生物识别认证对话框
- **THEN** 系统返回 `BiometricAuthResult`，其中 `success = false` 且 `failure = BiometricAuthFailure.userCancel`，不抛出异常

#### Scenario: 设备不支持
- **WHEN** 在不支持生物识别认证的设备上尝试认证
- **THEN** 系统返回 `BiometricAuthResult`，其中 `success = false` 且 `failure = BiometricAuthFailure.deviceNotSupported`，不抛出异常

#### Scenario: 无可用生物识别方法
- **WHEN** 尝试认证但未配置任何生物识别方法
- **THEN** 系统返回 `BiometricAuthResult`，其中 `success = false` 且 `failure = BiometricAuthFailure.noBiometricsAvailable`，不抛出异常

#### Scenario: 自定义认证原因
- **WHEN** 应用提供自定义的认证原因消息
- **THEN** 系统在认证过程中向用户显示提供的原因消息

#### Scenario: 自定义认证选项
- **WHEN** 应用提供自定义认证选项（biometricOnly、useErrorDialogs 等）
- **THEN** 系统使用提供的选项来配置认证行为

### Requirement: 生物识别认证结果
系统 SHALL 返回详细的认证结果，包括成功状态、失败类型和使用的生物识别类型。

#### Scenario: 结果结构
- **WHEN** 任何认证操作完成
- **THEN** 系统返回包含以下内容的 `BiometricAuthResult` 对象：
  - `success` (boolean): 认证是否成功
  - `failure` (BiometricAuthFailure?): 如果认证失败，则为失败类型；如果成功，则为 null
  - `biometricType` (BiometricType?): 成功认证时使用的生物识别类型；如果失败，则为 null

#### Scenario: 失败类型枚举
- **WHEN** 认证失败
- **THEN** 系统提供特定的 `BiometricAuthFailure` 值，指示失败原因：
  - `deviceNotSupported`: 设备不支持生物识别认证
  - `noBiometricsAvailable`: 未配置生物识别方法
  - `userCancel`: 用户取消了认证
  - `authenticationFailed`: 生物识别认证失败（错误的生物识别）
  - `systemError`: 发生系统/平台错误

### Requirement: 认证取消
系统 SHALL 提供停止正在进行的生物识别认证过程的能力。

#### Scenario: 停止认证
- **WHEN** 应用请求停止正在进行的认证
- **THEN** 系统取消认证过程，如果成功则返回 `true`

#### Scenario: 无认证进行时停止
- **WHEN** 请求停止但当前没有认证正在进行
- **THEN** 系统返回 `false`，不抛出异常

### Requirement: 错误处理
系统 SHALL 在生物识别操作期间优雅地处理平台异常和意外错误。

#### Scenario: 平台异常处理
- **WHEN** 在生物识别操作期间发生平台异常
- **THEN** 系统记录错误并返回 `BiometricAuthResult`，其中 `success = false` 且 `failure = BiometricAuthFailure.systemError`，不崩溃

#### Scenario: 意外错误处理
- **WHEN** 在生物识别操作期间发生意外错误
- **THEN** 系统记录错误（带严重级别）并返回 `BiometricAuthResult`，其中 `success = false` 且 `failure = BiometricAuthFailure.systemError`，不崩溃

#### Scenario: 查询操作的错误处理
- **WHEN** 在设备支持或可用性检查期间发生错误
- **THEN** 系统记录错误并返回安全的默认值（例如，布尔操作返回 `false`，列表操作返回空列表），不崩溃

