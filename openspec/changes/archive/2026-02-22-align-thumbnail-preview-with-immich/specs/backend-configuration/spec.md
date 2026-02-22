## ADDED Requirements

### Requirement: 媒体缩略图与预览图配置统一存放

媒体处理器所需的缩略图与预览图配置 SHALL 在后端统一配置中单处定义，键名清晰、与 Viper/环境变量映射一致。thumbnail 与 preview 各 SHALL 包含：单边 size（像素，表示长边上限）、format、quality。系统 SHALL NOT 为 thumbnail/preview 预设使用分散的 MaxWidth/MaxHeight/Crop 等多参数配置；仅使用单一 size 语义以与 Immich 对齐并降低维护成本。

#### Scenario: 配置键统一可覆盖

- **WHEN** 运维在配置文件或环境变量中设置 `media.thumbnail.size`、`media.preview.size` 等
- **THEN** 媒体处理器 SHALL 从该统一配置读取 thumbnail/preview 的 size、format、quality
- **AND** 配置加载优先级 SHALL 与现有后端配置一致（命令行 > 环境变量 > 配置文件 > 默认值）

#### Scenario: 默认值明确

- **WHEN** 未配置 media.thumbnail 或 media.preview 的 size
- **THEN** 系统 SHALL 使用代码或配置中定义的合理默认值（如 thumbnail 250、preview 1440）
- **AND** format、quality 亦 SHALL 有明确默认值并在同一配置块中定义
