# Change: 为 Live Photo 资产提供完整上传与关联支持

## Why

PrismBox 已在数据模型和前端设计文档中引入 `livePhotoVideoId` / `isMotionPhoto` 等字段，但当前上传链路仍按「单一文件」对待资产，未对 Live Photo / Motion Photo 做成对上传与服务端关联。  
这会导致：仅图片或仅视频被上传、服务端无法维护 Live Photo 关联、后续下载与播放无法按「一张动态照片」一致运作，与 Immich 已验证的设计存在差距。

## What Changes

- **上传能力扩展（asset-upload）**
  - 在上传逻辑中显式识别 Live Photo / Motion Photo，并将其拆解为「图片 + 视频」两个上传单元。
  - 约定 Live Photo 在服务端持久化为两条资产记录：主资产为图片，图片资产上保存 `livePhotoVideoId` 指向视频资产。
  - 对 Live Photo 上传执行「视频与图片成对上传 + 关联字段写入」协议，保证任一端完成后，服务端都能维护完整的 Live Photo 属性。
- **前后台上传流程对齐 Immich 行为**
  - 前台上传：参考 Immich `ForegroundUploadService._uploadSingleAsset`，在前台备份/手动上传链路中，为 Live Photo 先上传视频部分，再上传图片部分并携带 `livePhotoVideoId` 字段。
  - 后台上传：参考 Immich `BackgroundUploadService`，通过任务元数据与任务分组（普通备份组 + Live Photo 高优先级组）确保：
    - 第 1 个任务上传 Live Photo 视频并返回视频资产 ID；
    - 第 2 个任务上传图片，并将第 1 个任务的返回 ID 作为 `livePhotoVideoId` 写入请求字段。
  - 对上传失败/重试场景定义：图片成功、视频失败时须保留「待补视频」状态，反之亦然。
- **远程资产同步能力扩展（remote-asset-sync）**
  - 要求后端在远程资产列表 / 详情响应中返回 `livePhotoVideoId` 字段，并保证图片资产的该字段指向对应的视频资产 ID。
  - 客户端远程同步在写入本地 `remote_asset_entity` 时，须保留并更新 `livePhotoVideoId`，不得写死为 `null`。
  - 要求同步层不打乱 Live Photo 语义：图片与视频作为两条资产存在，但时间线展示以「图片资产 + livePhotoVideoId」为准。
- **与后续下载与播放的衔接**
  - 为下载模块后续实现提供前提条件：服务端始终能从图片资产的 `livePhotoVideoId` 解析到 Live Photo 视频资产。
  - 为媒体查看器 / 播放模块提供一致接口：通过 `isMotionPhoto` + `livePhotoVideoId` 判定「此资产为 Live Photo 且视频可寻址」。

## Impact

- **Affected specs**
  - `specs/asset-upload/spec.md`
    - ADDED: Live Photo / Motion Photo 成对上传与关联维护的明确要求。
  - `specs/remote-asset-sync/spec.md`
    - ADDED: 远程同步必须携带并写入 `livePhotoVideoId` 字段，确保 Live Photo 关联在本地可用。
- **Affected code (high level)**
  - 移动端：
    - 上传服务：`local_sync_service` / 备份上传服务 / 前台上传服务（参考 Immich `foreground_upload.service.dart` 和 `background_upload.service.dart`）。
    - 本地与远程资产模型：`BaseAsset.livePhotoVideoId` / `isMotionPhoto` 相关使用点。
  - 后端：
    - 资产上传 API：新增/确认 `livePhotoVideoId`（或等价字段）请求参数，并在图片资产上维护关联字段。
    - 远程资产列表 / 详情 API：在响应中返回 `livePhotoVideoId` 字段。
    - 资产持久化层：保证图片资产的 `livePhotoVideoId` 与视频资产 ID 的一致性与完整性。

