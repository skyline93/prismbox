# Live Photo 支持模块详细设计文档

## 目录

1. [模块概述](#模块概述)
2. [核心设计理念](#核心设计理念)
3. [数据模型](#数据模型)
4. [平台差异](#平台差异)
5. [上传流程](#上传流程)
6. [下载流程](#下载流程)
7. [Live Photo 资产预览展示方案](#live-photo-资产预览展示方案)
8. [后端 API 需求](#后端-api-需求)
9. [兼容性与降级](#兼容性与降级)
10. [实施顺序建议](#实施顺序建议)
11. [与现有规划及 Spec 的衔接](#与现有规划及-spec-的衔接)

---

## 模块概述

### 职责范围

Live Photo 支持模块是 PrismBox 移动端媒体处理能力的一部分，负责：

1. **Live Photo 上传**：检测、拆分图/视频，按顺序上传并建立关联
2. **Live Photo 下载**：识别关联资产，并行下载图与视频，按平台保存（含降级）
3. **Live Photo 资产预览展示**：在时间线/网格、媒体查看器等所有出现该资产的场景中，统一主图展示、Live 角标、播放入口与播放行为
4. **跨平台兼容**：区分 iOS Live Photo 与 Android Motion Photo，统一数据模型与交互

### 核心目标

1. **与 Immich 设计对齐**：数据模型、上传顺序、下载保存、预览播放行为与 Immich 一致，便于参考实现与迁移
2. **复用现有能力**：复用资产上传、下载、媒体查看器、视频播放器与图片加载管线，不重复造轮子
3. **平台体验一致**：iOS 可写回系统 Live Photo，Android 在限制下做合理降级，应用内预览与播放体验一致
4. **可维护与可测**：方案可拆分为明确任务，与 OpenSpec 及《PrismBox 媒体处理重构总规划》阶段 4 对应

### 设计原则

1. **主资产为图片**：时间线/列表以「一张 Live Photo」展示一条记录，对应图片资产；视频资产通过 `livePhotoVideoId` 关联
2. **先图后视频上传**：与 Immich 一致，先上传图片获得 ID，再上传视频并携带关联参数
3. **按需播放**：默认显示静态图，用户主动触发再加载并播放视频，避免自动播放带来的流量与性能问题
4. **降级可预期**：视频缺失、保存失败、播放失败时均有明确降级策略，不阻塞主流程

### 与其他模块的关系

```
Live Photo 支持模块
    │
    ├─→ 资产上传模块（asset-upload）：上传流程中增加 Live Photo 检测、拆分、顺序与关联
    ├─→ 备份上传下载模块：任务队列中识别 Live Photo 分组，先图后视频，进度与状态回调
    ├─→ 远程媒体资源同步模块：同步时写入 livePhotoVideoId，确保列表/详情包含关联信息
    ├─→ 媒体资源展示模块：缩略图沿用现有 ImageProvider；网格项增加 Live 角标；大图/查看器使用现有图片加载
    ├─→ 媒体查看器（media-viewer）：增加 Live 播放入口与播放状态，复用 ViewerImagePage/ViewerVideoPage/ViewerVideoManager
    ├─→ 数据库模块：使用现有 BaseAsset.livePhotoVideoId、remote_asset_entity.live_photo_video_id
    └─→ 页面导航模块：无直接依赖，仅通过资产数据与查看器入口体现
```

---

## 核心设计理念

### 本质定义

- **Live Photo = 一张主图 + 一段短视频**，在服务端存成两个独立资产，通过 ID 关联。
- **主资产**：以**图片**为主记录；图片资产上存 `livePhotoVideoId`，指向关联的**视频资产 ID**。
- **判定**：`isMotionPhoto = (livePhotoVideoId != null)`（PrismBox 已在 `BaseAsset` 上实现）。
- **产品命名**：iOS 称 Live Photo，Android 称 Motion Photo；产品层可统一称为「Live Photo」或「动态照片」。

### 与 Immich 的对齐

本方案在数据模型、上传顺序、下载保存、预览展示与播放行为上与 Immich 保持一致，便于直接参考 Immich 实现（如 `upload.service.dart`、`download.service.dart`、`is_motion_video_playing.provider.dart`、`MotionPhotoActionButton` 等）。

---

## 数据模型

### 已有基础（PrismBox）

- **BaseAsset**：已有 `livePhotoVideoId`、`isMotionPhoto` 属性。
- **本地/远程表**：`remote_asset_entity` 等已有 `live_photo_video_id` 列。
- **同步**：`timeline_provider_service` 已把服务端返回的 `livePhotoVideoId` 写入本地；若服务端未返回该字段，需在后端支持后取消置空逻辑（如 `remote_sync_service` 中的 `livePhotoVideoId: null`）。

### 模型约定

| 项目         | 约定说明 |
|--------------|----------|
| 主资产       | 图片资产；列表/时间线按「一张 Live Photo」展示一条记录，对应图片资产。 |
| 关联方向     | 仅图片 → 视频：图片存 `livePhotoVideoId`；视频资产是否反存「主图 ID」由后端可选实现。 |
| 去重与展示   | 作为 Live Photo 一部分的视频资产，在「全部照片/时间线」中可不单独成条，或标记为 Live Photo 视频避免重复展示（产品/后端策略）。 |

---

## 平台差异

| 平台       | 主图格式   | 视频形式                 | 本地获取方式 |
|------------|------------|--------------------------|--------------|
| **iOS**    | HEIC/JPG   | 独立 MOV                 | `photo_manager`：`isLivePhoto`；视频通过 `originFileWithSubtype`（或等价 API）取关联视频文件。 |
| **Android**| 常见图片   | 多为一枚文件内嵌（Motion Photo） | 文件名带 `.MP` 或通过 `photo_manager` 的 Motion Photo 支持获取图+视频；若仅能拿到一个文件，需解析/提取视频段（格式因厂商而异）。 |

上传、下载、保存时均需按平台分支处理；Android 保存到系统相册时若无 Motion Photo 写回 API，则降级为仅保存图片。

---

## 上传流程

### 检测与拆分

- **检测**：使用 `photo_manager` 的 `isLivePhoto`（或平台等价）判断是否为 Live Photo。
- **取文件**：
  - **iOS**：主图文件 + 通过 `originFileWithSubtype`（或当前插件等价 API）取关联视频文件。
  - **Android**：主图文件 + Motion Photo 视频（文件名 `.MP` 或插件提供的视频资源）。
- 若只能拿到「图+视频合在一个文件」：需约定是否由移动端解析出视频再上传，或暂只上传主图（降级）。

### 上传顺序与关联（对齐 Immich）

1. **先上传图片**
   - 调用现有上传接口上传主图。
   - 服务端返回**图片资产 ID**（如 `assetId` / `uuid`）。

2. **再上传视频**
   - 上传视频时，在请求中携带「关联的图片 ID」或服务端约定的 Live Photo 关联参数（Immich 为上传视频时带 `livePhotoVideoId`；若 PrismBox 后端字段名不同可适配）。
   - 服务端将视频与图片关联，并在图片资产上写入 `livePhotoVideoId`（或由后端根据关联上传自动维护）。

3. **任务与元数据**
   - 使用类似 `UploadTaskMetadata` 的元数据标记「Live Photo 的图/视频任务」。
   - 图片任务与视频任务可放在同一逻辑组（如 `kBackupLivePhotoGroup`），便于取消策略及「照片任务优先、视频随后」的排序。

### 失败与重试

- **图片成功、视频失败**：本地可保留「已上传图片、待重传视频」的状态，下次只重传视频并再次带上关联关系。
- **图片失败**：不创建或取消该 Live Photo 的视频任务。
- 与现有 `asset-upload` spec 的「上传结果返回、UUID 存储、失败不更新 isUploaded」等保持一致。

### 与现有模块的衔接

- **asset-upload**：在「上传执行 / 上传成功处理」中增加 Live Photo 分支：对 Live Photo 先执行图片上传 → 拿到 ID → 再执行视频上传并关联。
- **备份/后台上传**：任务队列中识别 Live Photo，按「图优先、再视频」排序；使用与 Immich 类似的分组（如 `kBackupGroup` / `kBackupLivePhotoGroup`）和回调，便于进度与状态上报。

---

## 下载流程

### 识别 Live Photo

- 从服务端或本地已同步的元数据中读取 `livePhotoVideoId`。
- 若 `livePhotoVideoId != null`，则该资产为 Live Photo，下载时需同时准备「图 + 视频」。

### 并行下载

- 创建**两个下载任务**：
  - 任务 1：图片（原图或缩略图/预览图，按现有策略）。
  - 任务 2：视频（通过 `livePhotoVideoId` 拼出视频 URL，如 `/assets/{livePhotoVideoId}/original` 或 playback）。
- 使用类似 `LivePhotosMetadata` 的结构标记：任务类型（image / video）、关联 ID（主图 id、livePhotoVideoId），以便两个任务都完成后做「成对保存」。

### 保存到本地（平台差异）

- **iOS**：两个任务都完成后，调用 `PhotoManager.editor.darwin.saveLivePhoto(imageFile, videoFile)`（或当前 `photo_manager` 的等价 API），将图+视频以系统 Live Photo 形式写回相册。
- **Android**：若系统/插件支持「Motion Photo 写回」，则用对应 API；否则**降级为「只保存图片」**（与 Immich 一致），视频仅作应用内播放用，不写回系统相册。

失败时：可降级为仅保存图片，并记录日志或提示「Live 视频未保存」。

### 任务组与回调（对齐 Immich 时序）

- 下载服务内部对「同一 Live Photo」的图+视频任务视为一组：两个都完成 → 触发 `saveLivePhoto`（或降级逻辑）→ 删除临时文件、清理任务记录（如 `deleteRecordsWithIds([imageId, videoId])`）。
- 进度：对组内两个任务统一上报进度（如 `onTaskProgress`），与现有下载模块的「分组并行下载」一致。

---

## Live Photo 资产预览展示方案

本节约定 Live Photo 在应用内**所有出现该资产的场景**中的预览与展示规则，形成统一、可落地的展示设计。

### 展示层级与场景

Live Photo 在应用内以「**一张主图 + 可选播放的短视频**」形式出现，需在所有出现该资产的地方统一规则。

| 场景                 | 说明                             | Live Photo 的展示要点 |
|----------------------|----------------------------------|------------------------|
| **时间线 / 照片列表**| 网格缩略图（如 SelectableMediaItem） | 主图作缩略图 + Live 角标，不显示时长 |
| **媒体查看器**       | 全屏大图/视频（MediaViewerPage） | 默认主图，提供「播放 Live」入口，播完后回到主图 |
| **收藏 / 相册 / 筛选页** | 与时间线同源的网格             | 与时间线一致：主图 + Live 角标 |
| **选择器（发帖、分享等）** | 可选媒体的网格                 | 与时间线一致，选中后仍按「一张 Live Photo」处理 |
| **搜索结果 / 其他列表** | 若复用同一网格组件             | 同上，统一主图 + Live 角标 |

原则：凡是用 `BaseAsset` 列表画网格或进查看器的地方，都按「主资产 = 图片、isMotionPhoto = 有/无」统一处理；不单独为 Live Photo 做一套列表数据结构。

---

### 时间线 / 网格中的展示

#### 主视觉（缩略图）

- **内容**：始终用**主图（图片资产）**作为缩略图。
- **加载**：与普通图片完全一致——沿用现有 `getThumbnailImageProvider(asset)`（或项目内等价逻辑）。Live Photo 的 `asset.type == image`，无需为 Live Photo 单独分支缩略图加载。
- **占位 / 渐进加载**：与当前图片策略一致（如占位符 → 缩略图 → 更高分辨率），不做额外阶段。

#### Live Photo 角标（与视频区分）

- **目的**：让用户一眼区分「普通图片」「视频」「Live Photo」。
- **显示条件**：`asset.isMotionPhoto == true`（即 `livePhotoVideoId != null`）。
- **位置**：与现有视频时长角标不重叠。当前视频角标在右下角（如 SelectableMediaItem 中的 _VideoIndicatorWithAsset），Live 角标建议：
  - **方案 A**：右下角，仅当「非视频」时显示 Live 角标（Live Photo 是图片，不会与视频时长同时出现）。
  - **方案 B**：固定一角（如右下）用同一块区域，按「视频 → 时长 / 非视频且 Live → Live 角标」规则显示，避免两个角标叠在一起。
- **样式**：小图标或短文案（如「Live」、动态图标），尺寸与视频角标接近，不压住主图过多；可带半透明底或描边以保证在亮/暗图上都可见。
- **无障碍**：角标需带语义（如「动态照片」），便于读屏与可访问性。

#### 不展示的内容

- **不显示时长**：Live Photo 主资产是图片，不应在网格上显示视频时长（与纯视频的时长角标区分）。
- **不显示播放按钮**：网格仅作预览，点击进入查看器后再提供播放；网格上不自动播放、不显示播放图标，避免误触和性能问题。

#### 点击 / 长按行为

- **点击**：进入媒体查看器，`initialAssetId` 为当前图片资产 ID；查看器内默认显示**静态主图**。
- **长按**：若当前为多选模式，与现有逻辑一致（进入选择等）；不做「长按即播 Live」——Live 播放统一在查看器内通过「长按主图」或「播放按钮」触发。

---

### 媒体查看器内的展示

#### 默认状态：静态主图

- **判定**：当前页对应的 `asset` 满足 `asset.isImage`（Live Photo 的主资产即为图片），因此与现有逻辑一致：**默认使用 ViewerImagePage 显示主图**。
- **加载**：主图走现有图片加载链（本地/远程、渐进式等）；**不在此阶段加载 Live 视频**。

#### 播放入口（何时出现、何时隐藏）

- **显示条件**：
  - `asset.isMotionPhoto == true`，且
  - 认为「有可播放的 Live 视频」：例如后端/本地能提供 `livePhotoVideoId` 对应资源（若尚未实现可先仅用 `livePhotoVideoId != null`，后续可加「可用性」检查）。
- **隐藏条件**：
  - `asset.isMotionPhoto == false`，或
  - 已知视频不可用（如 404、已删除、未下载且离线）：此时不显示播放按钮，或显示为不可用（灰显 + 提示）。
- **位置与形式**：与 Immich 类似，在**顶部工具栏**提供「播放 Live 视频」按钮（如 MotionPhotoActionButton）；可选在**主图区域支持长按**触发同一动作，便于发现。

#### 两种展示模式与状态

- **模式 1——静态图**：当前页展示 ViewerImagePage（主图）。
- **模式 2——播放 Live 视频**：当前页展示 ViewerVideoPage（或同等能力），视频源由 `livePhotoVideoId` 解析（本地文件路径或远程 URL），**不循环**，播完自动回到静态图。
- **状态管理**：建议用「当前是否正在播放 Live 视频」的单一状态（如 `isPlayingMotionVideoProvider` 或等价）驱动：
  - 显示/隐藏播放按钮；
  - 在「主图」与「Live 视频」之间切换用哪个子页面/组件；
  - 播完或用户停止时重置为「静态图」。

#### 切换与动效

- **从静态图 → 播放 Live**：用户点击播放按钮或长按主图后，切换到视频视图；可做短暂淡入或过渡，避免生硬切帧。
- **从 Live 视频 → 静态图**：播完自动切回主图；若用户暂停/停止，也可立即切回主图。同样建议简短过渡。
- **不循环**：Live 视频只播一遍，与普通视频的「可循环」区分，避免误以为是一段普通短视频。

#### 左右滑动与页面切换

- **滑到相邻页**：若当前正在播 Live 视频，应先**停止播放并释放播放器**，再切到相邻项；相邻项若是普通图片/视频，按现有逻辑展示；若相邻项也是 Live Photo，其默认仍为主图，用户再点播放则再进 Live 播放。
- **返回当前页**：从相邻页滑回本页时，应恢复为**静态主图**，不自动续播 Live 视频（与 Immich 行为一致，避免自动播放和状态错乱）。

#### 视频源与播放器复用

- **视频源**：
  - 本地：若已下载，用本地视频文件路径。
  - 远程：用 `livePhotoVideoId` 拼出与普通视频一致的 URL（如 `/assets/{livePhotoVideoId}/original` 或 playback）。
- **播放器**：复用现有 ViewerVideoManager / ViewerVideoPage（或项目内等价组件），不单独为 Live Photo 再做一套；仅传入「Live 视频」的源与「不循环、播完回图」等参数差异。

#### 控制栏与其它按钮

- **收藏、信息、分享等**：与普通图片/视频一致，基于当前 `asset`（主图资产）；不因「正在播 Live」而改变所属资产。
- **播放控制**：若 Live 播放时使用与普通视频相同的进度条、暂停等，可复用同一套控制逻辑；若产品希望 Live 仅「播放/停止」也可简化控制。

---

### 资源加载与缓存策略（预览展示）

#### 缩略图（网格）

- **只加载主图**：使用现有图片缩略图管线，键与普通图片一致（如按 asset 的 id/类型等）；**不预加载 Live 视频**，不增加网格滚动时的网络/解码负担。

#### 查看器内

- **首帧**：仅加载主图；用户未点「播放 Live」前不请求 Live 视频。
- **点击播放后**：再按需加载 Live 视频（本地路径或远程 URL），可显示加载中状态；若已存在视频缓存（与普通视频共用策略），优先用缓存。
- **预加载（可选）**：若产品需要更顺滑，可对「相邻页是否为 Live Photo」做轻量预加载（如只预加载元数据或低码率），不做强制要求，需权衡流量与体验。

#### 缓存分工

- **主图**：走现有图片缓存（缩略图 + 大图/原图），与普通图片一致。
- **Live 视频**：若项目有视频缓存（如转码/原片），Live 视频与普通视频使用同一套策略，键可用 `livePhotoVideoId` 或对应 URL。

---

### 预览展示的降级与异常

| 情况           | 表现 |
|----------------|------|
| **视频缺失**   | `livePhotoVideoId != null` 但视频 404/未下载/损坏：不显示或灰显播放按钮，仅显示主图；可选提示「动态视频暂不可用」。 |
| **播放失败**   | 用户点击播放后加载/解码失败：提示失败原因，并保持或切回静态主图视图。 |
| **无 livePhotoVideoId** | 视为普通图片：无 Live 角标、无播放按钮，仅主图展示。 |
| **数据不一致** | 若列表与详情中 `isMotionPhoto` 不一致，以当前页拿到的 `asset` 为准，避免依赖陈旧缓存导致误显示角标或按钮。 |

---

### 与现有模块的衔接（预览展示相关）

- **媒体资源展示模块**：
  - 缩略图：继续用现有 `getThumbnailImageProvider(asset)`，Live Photo 的 asset 是图片类型，无需改 Provider。
  - 网格项：在渲染网格单元时根据 `asset.isMotionPhoto` 决定是否叠加 **Live 角标**（位置与视频角标互斥或共用区域）。

- **媒体查看器（media-viewer）**：
  - 根据 `asset.isMotionPhoto` 与「视频是否可用」决定是否显示 **播放 Live 按钮**。
  - 根据「当前是否在播 Live」状态决定当前页是 ViewerImagePage 还是 ViewerVideoPage（视频源来自 `livePhotoVideoId`）。
  - 页面切换时释放/重置 Live 播放状态，保持与现有视频页生命周期一致。

- **照片时间线 / 选择器**：
  - 使用同一套网格组件与 BaseAsset 数据时，统一按「主图 + Live 角标」展示；进入查看器时传同一套 assetIds（以图片资产 ID 为条目），保证查看器内索引与列表一致。

---

### 可访问性、性能与一致性（预览展示）

- **可访问性**：Live 角标与「播放 Live 视频」按钮需带语义标签（如「动态照片」「播放动态视频」），便于读屏与辅助功能。
- **性能**：视频严格按需加载、不自动播放；网格不预加载 Live 视频；查看器内可选的预加载需控制并发与数量。
- **一致性**：除「多一个 Live 角标」和「查看器内多一个播放入口 + 图/视频切换」外，交互与普通图片、普通视频保持一致，减少用户学习成本。

---

## 后端 API 需求

当前 PrismBox 后端未检索到 `livePhoto` 相关实现，以下需与后端约定：

### 上传

- 视频上传接口是否支持「关联到已有图片资产」的参数（如 `livePhotoAssetId` 或 `relatedAssetId`）。
- 上传完成后，服务端是否在**图片资产**上写入 `livePhotoVideoId`（或等价字段），供同步与下载使用。

### 同步/元数据

- 拉取资产列表或资产详情时，是否返回 `livePhotoVideoId`。
- 若返回，PrismBox 的 `remote_sync_service` 应保留并写入本地（当前若写死 `null` 需改为使用服务端返回值）。

### 下载

- 视频下载 URL 是否与普通视频一致（如 `/assets/{id}/original` 或 `/assets/{id}/video/playback`），仅用 `livePhotoVideoId` 作为资产 ID 即可。

### 去重与展示（可选）

- 作为 Live Photo 一部分的视频资产，是否在「时间线/全部照片」中隐藏或标记，避免与主图重复展示（由产品决定）。

---

## 兼容性与降级

| 场景           | 策略 |
|----------------|------|
| 视频缺失       | 仅显示图片，不显示播放按钮或显示为不可用。 |
| iOS 保存失败   | 降级为只保存图片。 |
| Android 无写回 | 仅保存图片，应用内仍可播放已下载的视频。 |
| 播放失败       | 提示无法播放，保持静态图显示。 |

---

## 实施顺序建议

1. **与后端约定**：上传关联参数、同步返回 `livePhotoVideoId`、视频下载 URL。
2. **上传**：实现检测、拆图/视频、先图后视频、关联参数与任务分组。
3. **同步**：确保 `livePhotoVideoId` 从服务端写入本地表，不再置 `null`（在服务端支持后）。
4. **下载**：并行下载图+视频、成对保存、iOS/Android 保存与降级。
5. **预览展示**：网格 Live 角标、查看器播放入口、Provider、复用视频播放器、播完回图、资源加载与缓存策略。
6. **体验与收尾**：播放按钮与动效、可访问性、性能与一致性校验。

---

## 与现有规划及 Spec 的衔接

### 数据模型

- 已具备 `livePhotoVideoId`、`isMotionPhoto`，无需改表结构；仅需确保同步与后端返回一致。

### 《PrismBox 媒体处理重构总规划》阶段 4

- **4.1 上传流程**：对应本文「上传流程」一节（检测、顺序、任务元数据、失败策略）。
- **4.2 下载流程**：对应本文「下载流程」一节（识别、并行任务、保存、分组回调）。
- **4.3 预览与播放**：对应本文「Live Photo 资产预览展示方案」中媒体查看器与播放相关小节（入口、播放器复用、不循环、Provider）。
- **4.4 视觉标识与用户体验**：对应本文「Live Photo 资产预览展示方案」中时间线/网格角标、查看器播放入口、切换动效及可访问性/性能/一致性小节。

### OpenSpec 与模块文档

- **media-viewer**：在 spec 中增加「Live Photo 检测与播放入口」「播放状态 Provider」「页面切换时释放 Live 播放」等条款。
- **asset-upload**：在 spec 中增加「Live Photo 上传顺序与关联」「任务元数据与分组」等条款。
- **备份上传下载模块**：在模块文档中补充 Live Photo 任务分组与先图后视频的说明。
- **媒体资源展示模块**：在模块文档中补充网格项 Live 角标、缩略图沿用现有 Provider 的说明。

### 参考实现（Immich）

- 上传：`lib/services/upload.service.dart`、`lib/services/backup.service.dart`
- 下载：`lib/services/download.service.dart`、`lib/repositories/download.repository.dart`
- 预览播放：`lib/providers/asset_viewer/is_motion_video_playing.provider.dart`、`MotionPhotoActionButton`、`native_video_viewer.page.dart` 的 `createSource`
- iOS 保存：`PhotoManager.editor.darwin.saveLivePhoto`；Android 识别：`.MP` 或 `photo_manager` Motion Photo API

---

**文档版本**：1.1  
**最后更新**：2026-01  
**维护**：PrismBox 移动端团队  
**参考**：Immich 移动端媒体处理技术方案、PrismBox 媒体处理重构总规划、openspec/specs（asset-upload、media-viewer）、媒体资源展示模块详细设计文档
