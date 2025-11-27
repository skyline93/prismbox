# Immich Mobile 资源管理模块详解

> 聚焦移动端资源（Asset）管理的架构设计：如何同时维护“本地相册 + 远程相册 + UI 展示”的统一视图，支撑同步、元数据更新、删除、收藏等操作。

---

## 1. 模块定位与分层

| 层次               | 角色                                                                                                                             | 核心文件/组件                                                                                 |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| **Domain**         | 统一模型 `BaseAsset`/`LocalAsset`/`RemoteAsset` 与轻量服务 `domain/services/asset.service.dart`，对 UI 暴露统一的查询/监听接口。 | `lib/domain/models/asset/*`、`lib/domain/services/asset.service.dart`                         |
| **Infrastructure** | Drift/Isar 仓储，维护本地缓存、表结构、批量更新、EXIF/Stack 等信息。                                                             | `lib/infrastructure/repositories/local_asset.repository.dart`、`remote_asset.repository.dart` |
| **Application**    | 业务级资源服务：同步（ETag + Delta）、批量修改、删除、堆栈、备份联动等；通过 Riverpod Provider 与 UI 连接。                      | `lib/services/asset.service.dart`、`lib/providers/asset.provider.dart`                        |

这种分层让 UI 只依赖 Provider/Service，具体使用何种数据库或 API 被封装在下层，便于测试与扩展。

---

## 2. 数据建模与缓存策略

- **统一模型**：`BaseAsset` 定义通用字段，`LocalAsset`/`RemoteAsset` 扩展各自属性（如方向、可见性）；Domain 服务会自动判断通过本地/远程仓储读取，UI 只看到统一接口。
- **合并资产**：Local 与 Remote 通过 `checksum`、`stackId` 互相关联，仓储查询会把 peer ID 带上（如 `remoteId`），让删除/更新能按照 `AssetState`（local/remote/merged）精确执行。
- **双数据库**：Drift 存放远程资产与 EXIF、Stack、城市等高级信息；Isar 负责实体与旧数据兼容。同步时通过 `SyncService` 写入 Drift，UI 使用 Provider/Stream 获取实时数据。
- **ETag + Delta**：`services/asset.service.dart` 利用 `ETagRepository` + `SyncService` 先尝试增量更新（delta），必要时退回全量同步，平衡性能与一致性。

---

## 3. Domain 层 AssetService：统一视图

`lib/domain/services/asset.service.dart` 提供最靠近 UI 的查询能力：

```54:116:mobile/lib/domain/services/asset.service.dart
class AssetService {
  Future<BaseAsset?> getAsset(BaseAsset asset);
  Stream<BaseAsset?> watchAsset(BaseAsset asset);
  Future<List<RemoteAsset>> getStack(RemoteAsset asset);
  Future<ExifInfo?> getExif(BaseAsset asset);
  Future<double> getAspectRatio(BaseAsset asset);
  Future<List<(String, String)>> getPlaces(String userId);
  Future<(int local, int remote)> getAssetCounts();
}
```

- **自动路由**：根据资产类型选择本地或远程仓储，无需调用方传入额外信息。
- **响应式更新**：`watchAsset` 结合 Drift 流，为 UI 提供收藏/编辑后的实时刷新。
- **补全策略**：如 `getAspectRatio()` 缺少宽高，会回退到数据库或远程请求补齐。

Domain 层保持纯粹：不直接调用 OpenAPI，也不关心 UI，只面向数据。

---

## 4. Infrastructure 仓储

### 4.1 RemoteAssetRepository

- Drift 查询 join 本地表，自动附带 `localId`、stack 信息。
- 提供批量操作：`updateFavorite`、`updateVisibility`、`trash/restore/delete`、`updateLocation`、`updateDateTime` 等，均在一次事务中执行。
- `getPlaces()` 等查询直接利用 SQL group by，生成地图/搜索场景所需数据。

### 4.2 DriftLocalAssetRepository

- 读取时 join 远程表，附带 `remoteId`；`watch()` 提供流式更新。
- 支持 `getSourceAlbums`（含备份筛选）与 `getAssetsFromBackupAlbums`，为备份模块过滤提供数据。
- `updateHashes()`、`getHashedCount()` 等接口协助同步流程，确保资产能被远程匹配。

这种仓储设计让“合并资产”概念天然存在：同一条记录可同时拥有本地/远程 ID，业务层只需处理一个 Asset 对象即可。

---

## 5. Application `AssetService`（业务服务）

`lib/services/asset.service.dart` 是功能最多的部分，负责：

### 5.1 同步策略

- `refreshRemoteAssets()` 读取已同步用户 ID → 走 ETag/Delta → 失败时改走 Full Sync。
- Full Sync 按 10k 条分片请求，确保网络波动时也能逐段落地。
- `SyncService` 实际写入 Drift/Isar，`AssetService` 专心协调 API 与 Repository。

### 5.2 批量修改

- Favorite/Archive/Visibility/DateTime/Location 等统一调用 `_apiService.assetsApi.updateAssets()` 批量提交，然后更新本地对象并执行 `SyncService.upsertAssetsWithExif()`，让 UI 立刻反映结果。
- `setDescription()/getDescription()` 写入 OpenAPI/EXIF 仓储，实现描述同步。

### 5.3 删除策略

- **本地删除**：先调 `AssetMediaRepository` 删除设备文件，再根据 `AssetState` 更新 Isar/Drift（local 直接删，merged 则清除 `localId`）。  
- **远程删除**：调用 `assetsApi.deleteAssets()`。如果非强制删除则仅标记 `deletedAt`，强删则清空 `remoteId` 并把 merged 资产降级。  
- 删除流程与 UI 通过 `AssetNotifier` 的 `_deleteInProgress` 协调，防止多次触发。

### 5.4 元数据/堆栈

- `loadExif()` 缺啥补啥：如果本地没有 exif，则实时请求服务器，写回缓存。未来预留“本地 EXIF 解析”能力。
- `getStackAssets()` 基于 `stackId` 读取整组资产，Live Photo、连拍组可以一次性展示。
- `getRemotePeopleOfAsset()` 提供人物识别结果（来自服务器），供 People/Map/搜索使用。

### 5.5 备份联动

- `syncUploadedAssetToAlbums()` 会把备份候选与服务器上真实相册对应起来，实现“上传完自动归类”。
- 通过 `BackupRepository` + `BackupService` + `AlbumService` 组合，自动调用 `syncUploadAlbums()`。

---

## 6. Provider 与 UI 结合

`lib/providers/asset.provider.dart` 将服务暴露给 UI，并管理全局状态：

- `AssetNotifier` 继承 StateNotifier<bool>`，`state` 表示是否正在加载/删除，UI 可据此展示 Loading。
- `getAllAsset()` 同时触发用户同步、远程刷新、本地相册扫描，完成后 `ref.invalidate(memoryFutureProvider)`，保证 Memories、时间线等相关 Provider 更新。
- `assetDetailProvider` / `assetWatcher` 基于 Domain `AssetService.watchAsset()` + `loadExif()` 构建流式数据，为 Asset Viewer、详情页提供“实时 + 逐项补全”的能力。

UI（`widgets/asset_viewer`、`widgets/asset_grid`、`pages/photos` 等）仅需 `ref.watch(assetProvider)` 即可获取最新状态，不关心底层来源。

---

## 7. 系统级设计亮点

1. **合并资产模型**：统一处理 local/remote/merged 三种状态，删除/修改时自动走不同路径，减少大量 if/else。
2. **仓储层 join 设计**：查询自动补齐 peer 信息，业务层无需二次查表。
3. **响应式刷新**：Drift Stream + Riverpod Provider 确保任何编辑（收藏、描述、位置）都能即时反映在 UI。
4. **按需补全**：Exif、宽高、描述、人物数据不足时才去服务器获取，兼顾性能与体验。
5. **模块联动**：与备份、相册、People、地图、Memories 的 Provider 通过 `SyncService` 写入、`ref.invalidate` 协调，确保资源变更后全局一致。

---

## 8. 扩展与优化方向

- **本地 EXIF 解析**：目前 TODO，若补齐可在离线状态也支持编辑时间/地点。
- **实时同步**：现阶段主要依赖轮询 + delta 可选与 SyncStream 结合，未来可把资产表纳入 websocket 推送。
- **并发优化**：Full Sync 目前按用户顺序串行，可研究按 userId/shard 并发处理。
- **多设备协同**：利用 checksum + localId 机制，可进一步做“跨设备本地资源联动”，比如在平板编辑拍照后同步回手机。

---

通过上述分层和协同，资源管理模块把“本地图库 + 云端资产 + UI 操作”的复杂问题拆解为清晰可维护的组件，使得收藏、编辑、备份、搜索等上层功能可以在统一的资产视图上构建。后续若要扩展更多编辑能力或引入新媒体类型，只需按层次扩展对应 Service/Repository，即可融入现有架构。

