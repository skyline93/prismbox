## ADDED Requirements

### Requirement: 时间线网格 Live Photo 角标

时间线（及复用同一网格组件的收藏/相册/选择器等）SHALL 在网格缩略图右下角为 Live Photo 显示 Live 角标，与视频时长角标互斥；Live Photo 主资产为图片，缩略图使用主图且不显示时长、不自动播放。

#### Scenario: Live Photo 显示 Live 角标

- **WHEN** 网格项对应的资产满足 `asset.isMotionPhoto == true`（即 `livePhotoVideoId != null`）
- **THEN** 该网格项 SHALL 在右下角显示 Live 角标（小图标或短文案如「Live」）
- **AND** 角标样式与现有视频时长角标接近（尺寸、半透明底或描边），且与视频角标位置互斥（同一区域：视频显示时长，非视频且为 Live Photo 显示 Live 角标）

#### Scenario: 视频显示时长、Live Photo 不显示时长

- **WHEN** 网格项为普通视频（`asset.isVideo` 且非 Live Photo 主图）
- **THEN** 右下角 SHALL 显示视频时长角标（现有 _VideoIndicatorWithAsset 行为）
- **AND** 当网格项为 Live Photo 时，主资产为图片，SHALL 不显示视频时长，仅显示 Live 角标

#### Scenario: 缩略图与点击行为不变

- **WHEN** 网格项为 Live Photo
- **THEN** 缩略图 SHALL 使用主图（现有图片缩略图管线，如 getThumbnailImageProvider/MediaImageWidget），不预加载 Live 视频
- **AND** 点击 SHALL 进入媒体查看器且 initialAssetId 为当前图片资产 ID，查看器内默认显示静态主图
- **AND** 网格上不自动播放、不显示播放图标，避免误触与性能问题

#### Scenario: Live 角标无障碍

- **WHEN** 渲染 Live 角标
- **THEN** 角标 SHALL 带有语义标签（如「动态照片」），便于读屏与辅助功能

#### Scenario: 非 Live Photo 无 Live 角标

- **WHEN** 资产满足 `asset.isMotionPhoto == false`
- **THEN** 不显示 Live 角标，仅按现有逻辑显示视频时长（若为视频）或仅主图
- **AND** 以当前拿到的 `asset` 为准，避免陈旧缓存导致误显示角标
