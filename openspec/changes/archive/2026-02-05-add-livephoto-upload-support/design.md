## Context

PrismBox 已在移动端与本地数据库中引入 `livePhotoVideoId` / `isMotionPhoto` 字段，并在《Live Photo 支持模块详细设计文档》中明确了：

- Live Photo 的本质是「一张主图 + 一段短视频」；
- 主资产为图片，图片资产上保存 `livePhotoVideoId` 指向视频资产 ID；
- 时间线与查看器统一以图片资产为入口，通过 `isMotionPhoto` 判断是否存在可播放的视频部分。

Immich 在生产环境中已验证了一套完整的 Live Photo 方案，关键特征包括：

- 前台上传：在 `_uploadSingleAsset` 中识别 Live Photo，先上传视频文件，再上传图片文件，并在图片请求中携带 `livePhotoVideoId` 字段；
- 后台上传：通过 `UploadTaskMetadata` 与 `kBackupLivePhotoGroup` 等分组，将 Live Photo 拆解为两个上传任务，先视频后图片，第二个任务携带 `livePhotoVideoId`；
- 下载与保存：通过 `LivePhotosMetadata` 标记下载任务的 image/video 部分，两个任务都完成后调用 `saveLivePhoto` 以系统 Live Photo 形式保存，或降级为保存静态图；
- 预览与播放：通过 `isMotionPhoto` + 独立的「是否正在播放 Live 视频」 Provider 驱动 UI 模式切换。

本变更只聚焦于上传链路与远程数据的一致性，为后续下载与播放提供可靠的前提条件。

## Goals / Non-Goals

- Goals
  - G1: Live Photo / Motion Photo 在上传时必须作为「图片 + 视频」成对被处理，而非被当作单一文件。
  - G2: 服务端数据模型中，图片资产始终持有 `livePhotoVideoId` 指向对应的视频资产，客户端通过远程同步即可重建 Live Photo 语义。
  - G3: 前台与后台上传链路在 Live Photo 行为上一致，并尽可能复用 Immich 已验证的模式与实现思路。
  - G4: 在失败/重试场景下不产生孤立的图片或视频资产，或至少在客户端有可识别的「待补充」状态。
- Non-Goals
  - N1: 不在本提案中定义 Live Photo 的下载、保存到系统相册以及播放交互细节（这些在 Live Photo 模块设计文档的其他章节与媒体查看器 spec 中处理）。
  - N2: 不变更现有非 Live Photo 资产的上传协议与 API；仅在 Live Photo 场景下补充字段与控制逻辑。
  - N3: 不在本次变更中调整时间线去重策略（例如是否隐藏 Live Photo 的视频资产），仅在后端层面允许该能力。

## Decisions

- Decision 1: **服务端关联方向与字段约定**
  - 图片资产为主资产，图片记录上保存 `livePhotoVideoId` 字段，指向 Live Photo 的视频资产 ID。
  - 下载与播放模块统一通过「图片资产 + `livePhotoVideoId`」来恢复 Live Photo 信息，而不直接依赖视频资产反向引用。
  - 与 Immich 的设计保持一致，以便最大程度复用其上传、下载与查看器逻辑。

- Decision 2: **上传顺序与字段携带策略**
  - 为简化客户端实现并与 Immich 保持一致，采用「**先上传视频，再上传图片，并在图片请求中携带 `livePhotoVideoId`**」的顺序：
    - 视频上传时不携带特殊 Live Photo 字段，作为普通视频资产创建。
    - 后续图片上传请求在字段中携带 `livePhotoVideoId=<视频资产ID>`，由服务端在保存图片资产时建立关联。
  - 设计文档中提到的「先图后视频」原则在对外行为上与此等价（最终主资产仍为图片，视频 ID 写入图片记录）；本提案以 Immich 的实证实现为主导，对内部上传顺序不作强约束，仅在 spec 中要求「图片与视频必须成对上传且服务端最终维护关联」。

- Decision 3: **前台与后台上传的一致抽象**
  - 前台上传（类似 Immich `ForegroundUploadService`）直接在一次调用中完成「视频 + 图片」成对上传：在同一函数中获取两个文件，先视频后图片，并在图片请求中携带 `livePhotoVideoId`。
  - 后台上传（类似 Immich `BackgroundUploadService`）采用任务队列抽象：
    - 第 1 个任务上传视频；完成后在回调中解析响应 ID，并生成第 2 个上传任务。
    - 第 2 个任务上传图片，并在任务字段中携带 `livePhotoVideoId` 字段。
  - 两者共同依赖统一的字段命名与服务端行为，保证无论哪条上传路径，都能得到相同的最终数据形态。

- Decision 4: **远程同步中的 Live Photo 字段处理**
  - `remote-asset-sync` 能力必须把来自服务端的 `livePhotoVideoId` 原样写入本地 `remote_asset_entity` 表，不允许在同步层「强制置空」。
  - 客户端在构建 `BaseAsset` 时，以 `livePhotoVideoId != null` 作为 `isMotionPhoto` 判定依据之一，与当前数据模型保持一致。

## Risks / Trade-offs

- Risk 1: **上传顺序与设计文档描述不完全一致**
  - 描述中的「先图后视频」与 Immich 实际实现的「先视频后图」存在表述差异。
  - Mitigation: 在 spec 中不强制约束网络请求顺序，而是约束最终结果（图片需指向视频资产 ID）；在实现文档中明确我们采用 Immich 的顺序，以降低实现复杂度。

- Risk 2: **部分上传失败导致数据不完全成对**
  - 例如视频上传成功、图片上传失败，或反之。
  - Mitigation:
    - 在客户端任务管理中记录「Live Photo 剩余部分待上传」状态，并在下次备份时重试缺失部分。
    - 在服务端提供后台清理策略（如可选：对长期孤立的视频资产进行审计和清理），但这超出本次变更范围。

- Risk 3: **多平台与多客户端并发上传**
  - 多设备可能对同一 Live Photo 执行上传，或仅上传图片/视频的一部分。
  - Mitigation:
    - 复用现有基于 hash 的去重能力，避免重复存储同一文件。
    - 在 spec 中强调：即使多设备只上传其中一部分，服务端仍应允许后续补齐另一部分并完成关联。

## Migration Plan

- Phase 1: 协议与字段约定
  - 与后端对齐上传接口与远程资产响应中的 `livePhotoVideoId` 字段设计。
  - 确认数据表结构已支持 `livePhotoVideoId`，或补充必要列与索引。

- Phase 2: 上传链路实现
  - 在前台与后台上传服务中实现 Live Photo 拆解与成对上传逻辑，优先保证「图片 + 视频都能成功上传」以及「图片资产拥有正确的 `livePhotoVideoId`」。
  - 确保现有非 Live Photo 上传路径不受影响（通过测试与灰度验证）。

- Phase 3: 远程同步与本地模型
  - 更新远程同步代码以正确读取/写入 `livePhotoVideoId`。
  - 校验 `BaseAsset.isMotionPhoto` 逻辑在新数据下工作正常。

- Phase 4: 验证与回归
  - 使用典型设备（iOS Live Photo 与 Android Motion Photo）在测试环境中跑通完整链路：本地拍摄 → 上传 → 后端检查 → 远程同步 → 本地模型检查。
  - 与后续「下载与播放」变更对齐接口约定，确认本变更提供的字段足够支撑后续实现。

## Open Questions

- Q1: 后端是否需要为 Live Photo 视频资产提供反向引用（例如 `livePhotoStillId`），用于调试与后台管理？（目前不强制要求）
- Q2: 是否需要对「作为 Live Photo 一部分的视频资产」在时间线 / 列表中隐藏或打标，避免与图片资产重复展示？（更偏产品与后端 API 设计，需要单独评估）
- Q3: Android 端若只拿到「图+视频同文件的 Motion Photo」，解析视频段的责任由移动端承担还是由后端/工具链处理？本提案仅假设「客户端已能拿到一张图片文件和一段视频文件」。  

