# Immich 移动端 Drift 数据库架构设计文档

## 目录

1. [架构概览](#架构概览)
2. [核心设计原则](#核心设计原则)
3. [数据库配置](#数据库配置)
4. [表结构设计](#表结构设计)
5. [关系与外键约束](#关系与外键约束)
6. [索引设计](#索引设计)
7. [查询优化策略](#查询优化策略)
8. [数据迁移方案](#数据迁移方案)
9. [最佳实践](#最佳实践)

---

## 架构概览

Immich 移动端采用 **Drift (SQLite)** 作为主数据库，用于存储所有关系型数据。数据库设计遵循以下核心理念：

- **本地与远程数据分离**：本地资产和远程资产分别存储，通过 `checksum` 关联
- **严格模式**：所有表使用 `WITHOUT ROWID` 和 `STRICT` 模式，提升性能和类型安全
- **外键约束**：完整的外键约束保证数据一致性
- **版本化迁移**：支持渐进式数据库结构升级

### 数据库基本信息

- **数据库名称**：`immich`
- **当前 Schema 版本**：13
- **存储引擎**：SQLite
- **跨 Isolate 支持**：是（`shareAcrossIsolates: true`）

---

## 核心设计原则

### 1. 表设计原则

- **主键策略**：所有表使用业务主键（String 类型），不使用自增 ID
- **严格模式**：所有表启用 `STRICT` 模式，确保类型安全
- **无 ROWID**：所有表使用 `WITHOUT ROWID`，提升查询性能
- **默认值**：时间字段使用 `currentDateAndTime`，布尔字段提供默认值

### 2. 数据分离原则

- **本地数据**：存储在 `local_*` 表中，表示设备上的原始数据
- **远程数据**：存储在 `remote_*` 表中，表示服务器同步的数据
- **关联机制**：通过 `checksum`（文件哈希）关联本地和远程资产

### 3. 软删除策略

- **远程资产**：使用 `deletedAt` 字段实现软删除
- **本地资产**：删除后移动到 `trashed_local_asset_entity` 表
- **查询过滤**：查询时自动过滤已删除数据

---

## 数据库配置

### SQLite PRAGMA 设置

数据库打开时自动配置以下参数：

```sql
PRAGMA foreign_keys = ON;           -- 启用外键约束
PRAGMA synchronous = NORMAL;         -- 平衡性能和数据安全
PRAGMA journal_mode = WAL;           -- 使用 WAL 模式提升并发性能
PRAGMA busy_timeout = 30000;         -- 30 秒超时，避免并发冲突
```

### 跨 Isolate 支持

数据库配置 `shareAcrossIsolates: true`，允许在多个 Dart Isolate 中共享数据库连接，这对于后台任务处理非常重要。

---

## 表结构设计

### 1. 用户与认证相关表

#### 1.1 AuthUserEntity - 认证用户表

存储当前登录用户的信息，包括配额和锁定文件夹功能。

**字段说明**：
- `id` (String, PK): 用户唯一标识
- `name` (String): 用户名称
- `email` (String): 用户邮箱
- `isAdmin` (Bool): 是否为管理员
- `hasProfileImage` (Bool): 是否有头像
- `profileChangedAt` (DateTime): 头像更新时间
- `avatarColor` (Int): 头像颜色枚举
- `quotaSizeInBytes` (Int): 配额大小（字节）
- `quotaUsageInBytes` (Int): 已使用配额（字节）
- `pinCode` (String, Nullable): 锁定文件夹 PIN 码

**设计要点**：
- 单行存储，只保存当前登录用户
- 配额信息实时更新

#### 1.2 UserEntity - 用户基础信息表

存储系统中所有用户的基础信息，支持多用户场景。

**字段说明**：
- `id` (String, PK): 用户唯一标识
- `name` (String): 用户名称
- `email` (String): 用户邮箱
- `hasProfileImage` (Bool): 是否有头像
- `profileChangedAt` (DateTime): 头像更新时间
- `avatarColor` (Int): 头像颜色枚举

**关系**：
- 被多个表引用（RemoteAssetEntity, RemoteAlbumEntity, PersonEntity 等）
- 删除策略：CASCADE（删除用户时级联删除相关数据）

#### 1.3 UserMetadataEntity - 用户元数据表

存储用户的扩展元数据，使用 JSON 格式。

**字段说明**：
- `userId` (String, PK): 用户 ID（外键 → UserEntity.id）
- `key` (Int, PK): 元数据键（枚举类型）
- `value` (Blob): JSON 格式的元数据值

**设计要点**：
- 复合主键：`(userId, key)`
- 使用 JSONB 类型转换器存储复杂数据结构
- 支持动态扩展用户属性

#### 1.4 PartnerEntity - 合作伙伴关系表

存储用户之间的共享关系。

**字段说明**：
- `sharedById` (String, PK): 共享者用户 ID（外键 → UserEntity.id）
- `sharedWithId` (String, PK): 被共享者用户 ID（外键 → UserEntity.id）
- `inTimeline` (Bool): 是否在时间线中显示

**设计要点**：
- 复合主键：`(sharedById, sharedWithId)`
- 双向关系需要两条记录
- 删除策略：CASCADE

---

### 2. 资产相关表

#### 2.1 LocalAssetEntity - 本地资产表

存储设备上的原始媒体文件信息。

**字段说明**（继承自 `AssetEntityMixin`）：
- `id` (String, PK): 资产唯一标识（通常是设备文件 ID）
- `name` (String): 文件名
- `type` (Int): 资产类型枚举（图片/视频）
- `createdAt` (DateTime): 创建时间
- `updatedAt` (DateTime): 更新时间
- `width` (Int, Nullable): 宽度（像素）
- `height` (Int, Nullable): 高度（像素）
- `durationInSeconds` (Int, Nullable): 视频时长（秒）

**本地资产特有字段**：
- `checksum` (String, Nullable): 文件哈希值（用于与远程资产关联）
- `isFavorite` (Bool): 是否收藏（用于备份时同步服务器状态）
- `orientation` (Int): 图片方向（0-8，EXIF 方向值）

**索引**：
- `idx_local_asset_checksum` (checksum): 用于快速查找和关联

**设计要点**：
- `checksum` 可为空，因为文件可能尚未计算哈希
- `isFavorite` 用于在备份过程中同步服务器端的收藏状态
- `orientation` 存储 EXIF 方向信息，用于正确显示图片

#### 2.2 RemoteAssetEntity - 远程资产表

存储从服务器同步的资产信息。

**字段说明**（继承自 `AssetEntityMixin`）：
- `id` (String, PK): 服务器端资产 ID
- `name` (String): 文件名
- `type` (Int): 资产类型
- `createdAt` (DateTime): 创建时间
- `updatedAt` (DateTime): 更新时间
- `width` (Int, Nullable): 宽度
- `height` (Int, Nullable): 高度
- `durationInSeconds` (Int, Nullable): 视频时长

**远程资产特有字段**：
- `checksum` (String): 文件哈希值（必填，用于去重和关联）
- `isFavorite` (Bool): 是否收藏
- `ownerId` (String): 所有者用户 ID（外键 → UserEntity.id）
- `localDateTime` (DateTime, Nullable): 本地拍摄时间
- `thumbHash` (String, Nullable): 缩略图哈希
- `deletedAt` (DateTime, Nullable): 删除时间（软删除）
- `livePhotoVideoId` (String, Nullable): Live Photo 视频 ID
- `visibility` (Int): 可见性枚举（时间线/归档等）
- `stackId` (String, Nullable): 堆叠 ID
- `libraryId` (String, Nullable): 库 ID（支持多库）

**索引**：
- `idx_remote_asset_owner_checksum` (owner_id, checksum): 复合索引，用于快速查找
- `UQ_remote_assets_owner_checksum` (owner_id, checksum) WHERE library_id IS NULL: 条件唯一索引
- `UQ_remote_assets_owner_library_checksum` (owner_id, library_id, checksum) WHERE library_id IS NOT NULL: 多库唯一索引
- `idx_remote_asset_checksum` (checksum): 用于关联本地资产

**设计要点**：
- 使用条件唯一索引支持单库和多库场景
- `checksum` 与 `ownerId` 组合保证唯一性
- 软删除通过 `deletedAt` 实现
- 支持 Live Photo（iOS）和堆叠功能

#### 2.3 RemoteExifEntity - 远程资产 EXIF 信息表

存储资产的详细 EXIF 元数据，与 RemoteAssetEntity 一对一关系。

**字段说明**：
- `assetId` (String, PK): 资产 ID（外键 → RemoteAssetEntity.id）
- `fileSize` (Int, Nullable): 文件大小（字节）
- `dateTimeOriginal` (DateTime, Nullable): 原始拍摄时间
- `timeZone` (String, Nullable): 时区
- `make` (String, Nullable): 相机品牌
- `model` (String, Nullable): 相机型号
- `lens` (String, Nullable): 镜头信息
- `exposureTime` (String, Nullable): 曝光时间
- `fNumber` (Real, Nullable): 光圈值
- `focalLength` (Real, Nullable): 焦距（毫米）
- `iso` (Int, Nullable): ISO 感光度
- `latitude` (Real, Nullable): 纬度
- `longitude` (Real, Nullable): 经度
- `city` (String, Nullable): 城市
- `state` (String, Nullable): 州/省
- `country` (String, Nullable): 国家
- `description` (String, Nullable): 描述
- `orientation` (String, Nullable): 方向字符串
- `rating` (Int, Nullable): 评分
- `projectionType` (String, Nullable): 投影类型（用于全景图）

**索引**：
- `idx_lat_lng` (latitude, longitude): 地理位置索引，用于地图视图和地理位置查询

**设计要点**：
- 一对一关系，使用资产 ID 作为主键
- 大部分字段可为空，因为不是所有资产都有完整 EXIF 信息
- 地理位置索引支持高效的地理位置查询和聚合

#### 2.4 TrashedLocalAssetEntity - 已删除本地资产表

存储已从设备删除但尚未从服务器删除的本地资产信息。

**字段说明**（继承自 `AssetEntityMixin`）：
- `id` (String, PK): 资产 ID
- `albumId` (String, PK): 相册 ID
- `name` (String): 文件名
- `type` (Int): 资产类型
- `createdAt` (DateTime): 创建时间
- `updatedAt` (DateTime): 更新时间
- `width` (Int, Nullable): 宽度
- `height` (Int, Nullable): 高度
- `durationInSeconds` (Int, Nullable): 视频时长
- `checksum` (String, Nullable): 文件哈希
- `isFavorite` (Bool): 是否收藏
- `orientation` (Int): 图片方向

**索引**：
- `idx_trashed_local_asset_checksum` (checksum): 用于查找和恢复
- `idx_trashed_local_asset_album` (album_id): 用于按相册查询

**设计要点**：
- 复合主键：`(id, albumId)`，因为同一资产可能属于多个相册
- 用于处理设备删除但服务器仍存在的情况
- 支持恢复操作

---

### 3. 相册相关表

#### 3.1 LocalAlbumEntity - 本地相册表

存储设备上的相册信息。

**字段说明**：
- `id` (String, PK): 相册唯一标识（设备相册 ID）
- `name` (String): 相册名称
- `updatedAt` (DateTime): 更新时间
- `backupSelection` (Int): 备份选择枚举（none/selected/excluded）
- `isIosSharedAlbum` (Bool): 是否为 iOS 共享相册
- `linkedRemoteAlbumId` (String, Nullable): 关联的远程相册 ID（外键 → RemoteAlbumEntity.id）
- `marker_` (Bool, Nullable): 标记字段（用于标记和清理算法）

**关系**：
- `linkedRemoteAlbumId` → RemoteAlbumEntity.id (SET NULL): 删除远程相册时设为空

**设计要点**：
- `backupSelection` 控制哪些相册需要备份
- `linkedRemoteAlbumId` 用于将本地相册与服务器相册关联
- `marker_` 用于实现标记-清理算法，识别不再使用的数据

#### 3.2 LocalAlbumAssetEntity - 本地相册-资产关联表

存储本地相册与资产的关联关系。

**字段说明**：
- `assetId` (String, PK): 资产 ID（外键 → LocalAssetEntity.id）
- `albumId` (String, PK): 相册 ID（外键 → LocalAlbumEntity.id）
- `marker_` (Bool, Nullable): 标记字段（用于标记和清理）

**关系**：
- `assetId` → LocalAssetEntity.id (CASCADE)
- `albumId` → LocalAlbumEntity.id (CASCADE)

**设计要点**：
- 复合主键：`(assetId, albumId)`
- 支持多对多关系（一个资产可以属于多个相册）
- `marker_` 用于标记-清理算法

#### 3.3 RemoteAlbumEntity - 远程相册表

存储服务器端的相册信息。

**字段说明**：
- `id` (String, PK): 相册唯一标识
- `name` (String): 相册名称
- `description` (String): 相册描述
- `createdAt` (DateTime): 创建时间
- `updatedAt` (DateTime): 更新时间
- `ownerId` (String): 所有者用户 ID（外键 → UserEntity.id）
- `thumbnailAssetId` (String, Nullable): 缩略图资产 ID（外键 → RemoteAssetEntity.id）
- `isActivityEnabled` (Bool): 是否启用活动功能
- `order` (Int): 排序方式枚举

**关系**：
- `ownerId` → UserEntity.id (CASCADE)
- `thumbnailAssetId` → RemoteAssetEntity.id (SET NULL)

**设计要点**：
- 支持相册共享和协作
- `thumbnailAssetId` 可为空，删除资产时自动设为空
- `order` 控制相册内资产的排序方式

#### 3.4 RemoteAlbumAssetEntity - 远程相册-资产关联表

存储远程相册与资产的关联关系。

**字段说明**：
- `assetId` (String, PK): 资产 ID（外键 → RemoteAssetEntity.id）
- `albumId` (String, PK): 相册 ID（外键 → RemoteAlbumEntity.id）

**关系**：
- `assetId` → RemoteAssetEntity.id (CASCADE)
- `albumId` → RemoteAlbumEntity.id (CASCADE)

**设计要点**：
- 复合主键：`(assetId, albumId)`
- 支持多对多关系
- 删除资产或相册时自动清理关联

#### 3.5 RemoteAlbumUserEntity - 远程相册用户权限表

存储相册的共享用户和权限信息。

**字段说明**：
- `albumId` (String, PK): 相册 ID（外键 → RemoteAlbumEntity.id）
- `userId` (String, PK): 用户 ID（外键 → UserEntity.id）
- `role` (Int): 用户角色枚举（所有者/编辑者/查看者等）

**关系**：
- `albumId` → RemoteAlbumEntity.id (CASCADE)
- `userId` → UserEntity.id (CASCADE)

**设计要点**：
- 复合主键：`(albumId, userId)`
- 支持相册共享和权限管理
- 删除相册或用户时自动清理

---

### 4. 其他功能表

#### 4.1 MemoryEntity - 回忆表

存储自动生成的回忆（Memories）信息。

**字段说明**：
- `id` (String, PK): 回忆唯一标识
- `createdAt` (DateTime): 创建时间
- `updatedAt` (DateTime): 更新时间
- `deletedAt` (DateTime, Nullable): 删除时间（软删除）
- `ownerId` (String): 所有者用户 ID（外键 → UserEntity.id）
- `type` (Int): 回忆类型枚举
- `data` (String): JSON 格式的回忆数据
- `isSaved` (Bool): 是否已保存
- `memoryAt` (DateTime): 回忆时间点
- `seenAt` (DateTime, Nullable): 查看时间
- `showAt` (DateTime, Nullable): 显示开始时间
- `hideAt` (DateTime, Nullable): 显示结束时间

**关系**：
- `ownerId` → UserEntity.id (CASCADE)

**设计要点**：
- 支持时间窗口控制（showAt/hideAt）
- 使用软删除保留历史记录
- `data` 字段存储 JSON，支持灵活的回忆配置

#### 4.2 MemoryAssetEntity - 回忆-资产关联表

存储回忆包含的资产。

**字段说明**：
- `assetId` (String, PK): 资产 ID（外键 → RemoteAssetEntity.id）
- `memoryId` (String, PK): 回忆 ID（外键 → MemoryEntity.id）

**关系**：
- `assetId` → RemoteAssetEntity.id (CASCADE)
- `memoryId` → MemoryEntity.id (CASCADE)

**设计要点**：
- 复合主键：`(assetId, memoryId)`
- 一个回忆可以包含多个资产
- 一个资产可以属于多个回忆

#### 4.3 StackEntity - 堆叠表

存储资产的堆叠信息（如连拍照片）。

**字段说明**：
- `id` (String, PK): 堆叠唯一标识
- `createdAt` (DateTime): 创建时间
- `updatedAt` (DateTime): 更新时间
- `ownerId` (String): 所有者用户 ID（外键 → UserEntity.id）
- `primaryAssetId` (String): 主资产 ID（堆叠的代表资产）

**关系**：
- `ownerId` → UserEntity.id (CASCADE)

**设计要点**：
- 堆叠用于组织相关资产（如连拍、Live Photo）
- `primaryAssetId` 标识堆叠的代表资产
- 在时间线中只显示主资产

#### 4.4 PersonEntity - 人物表

存储人脸识别识别出的人物信息。

**字段说明**：
- `id` (String, PK): 人物唯一标识
- `createdAt` (DateTime): 创建时间
- `updatedAt` (DateTime): 更新时间
- `ownerId` (String): 所有者用户 ID（外键 → UserEntity.id）
- `name` (String): 人物名称
- `faceAssetId` (String, Nullable): 代表头像资产 ID
- `isFavorite` (Bool): 是否收藏
- `isHidden` (Bool): 是否隐藏
- `color` (String, Nullable): 人物颜色标识
- `birthDate` (DateTime, Nullable): 生日

**关系**：
- `ownerId` → UserEntity.id (CASCADE)

**设计要点**：
- 支持人物收藏和隐藏功能
- `faceAssetId` 用于显示人物头像
- `color` 用于界面显示区分

#### 4.5 AssetFaceEntity - 人脸识别表

存储资产中检测到的人脸信息。

**字段说明**：
- `id` (String, PK): 人脸唯一标识
- `assetId` (String): 资产 ID（外键 → RemoteAssetEntity.id）
- `personId` (String, Nullable): 关联的人物 ID（外键 → PersonEntity.id）
- `imageWidth` (Int): 图片宽度
- `imageHeight` (Int): 图片高度
- `boundingBoxX1` (Int): 边界框左上角 X 坐标
- `boundingBoxY1` (Int): 边界框左上角 Y 坐标
- `boundingBoxX2` (Int): 边界框右下角 X 坐标
- `boundingBoxY2` (Int): 边界框右下角 Y 坐标
- `sourceType` (String): 识别来源类型

**关系**：
- `assetId` → RemoteAssetEntity.id (CASCADE)
- `personId` → PersonEntity.id (SET NULL)

**设计要点**：
- 存储人脸的边界框坐标，用于在图片上标注
- `personId` 可为空，表示未识别的人物
- 删除资产时自动清理人脸信息

#### 4.6 StoreEntity - 键值存储表

存储应用的配置和状态信息。

**字段说明**：
- `id` (Int, PK): 存储键（枚举类型）
- `stringValue` (String, Nullable): 字符串值
- `intValue` (Int, Nullable): 整数值

**设计要点**：
- 通用的键值存储，支持字符串和整数类型
- 用于存储应用配置、同步状态等
- 替代了原来的 Isar StoreValue

---

## 关系与外键约束

### 外键删除策略

数据库使用以下外键删除策略：

1. **CASCADE（级联删除）**：
   - 删除用户时，自动删除其所有资产、相册、人物等
   - 删除资产时，自动删除关联的 EXIF、人脸、相册关联等
   - 删除相册时，自动删除相册-资产关联

2. **SET NULL（设为空）**：
   - 删除远程相册时，本地相册的 `linkedRemoteAlbumId` 设为空
   - 删除资产时，相册的 `thumbnailAssetId` 设为空
   - 删除人物时，人脸的 `personId` 设为空

### 核心关系图

```
UserEntity (用户)
  ├── RemoteAssetEntity (远程资产) [CASCADE]
  ├── RemoteAlbumEntity (远程相册) [CASCADE]
  ├── PersonEntity (人物) [CASCADE]
  ├── MemoryEntity (回忆) [CASCADE]
  ├── StackEntity (堆叠) [CASCADE]
  └── PartnerEntity (合作伙伴) [CASCADE]

RemoteAssetEntity (远程资产)
  ├── RemoteExifEntity (EXIF 信息) [CASCADE]
  ├── AssetFaceEntity (人脸) [CASCADE]
  ├── RemoteAlbumAssetEntity (相册关联) [CASCADE]
  └── MemoryAssetEntity (回忆关联) [CASCADE]

RemoteAlbumEntity (远程相册)
  ├── RemoteAlbumAssetEntity (资产关联) [CASCADE]
  ├── RemoteAlbumUserEntity (用户权限) [CASCADE]
  └── LocalAlbumEntity.linkedRemoteAlbumId [SET NULL]

LocalAssetEntity (本地资产)
  └── LocalAlbumAssetEntity (相册关联) [CASCADE]

LocalAlbumEntity (本地相册)
  └── LocalAlbumAssetEntity (资产关联) [CASCADE]
```

---

## 索引设计

### 索引策略

索引设计遵循以下原则：

1. **唯一性保证**：使用唯一索引防止数据重复
2. **查询优化**：为常用查询字段创建索引
3. **条件索引**：使用部分索引（WHERE 子句）优化特定场景
4. **复合索引**：为多字段查询创建复合索引

### 详细索引列表

#### 1. 资产相关索引

**LocalAssetEntity**：
- `idx_local_asset_checksum` (checksum)
  - 用途：快速查找本地资产，用于与远程资产关联

**RemoteAssetEntity**：
- `idx_remote_asset_owner_checksum` (owner_id, checksum)
  - 用途：按用户和哈希查找资产，支持快速去重
- `UQ_remote_assets_owner_checksum` (owner_id, checksum) WHERE library_id IS NULL
  - 用途：单库场景的唯一性约束
- `UQ_remote_assets_owner_library_checksum` (owner_id, library_id, checksum) WHERE library_id IS NOT NULL
  - 用途：多库场景的唯一性约束
- `idx_remote_asset_checksum` (checksum)
  - 用途：通过哈希关联本地和远程资产

**TrashedLocalAssetEntity**：
- `idx_trashed_local_asset_checksum` (checksum)
  - 用途：查找已删除资产，支持恢复
- `idx_trashed_local_asset_album` (album_id)
  - 用途：按相册查询已删除资产

#### 2. EXIF 相关索引

**RemoteExifEntity**：
- `idx_lat_lng` (latitude, longitude)
  - 用途：地理位置查询，支持地图视图和地理位置聚合

### 索引使用场景

1. **资产关联查询**：
   - 通过 `checksum` 索引快速匹配本地和远程资产
   - 支持增量同步和去重

2. **用户资产查询**：
   - 通过 `(owner_id, checksum)` 复合索引快速查找用户资产
   - 支持多库场景的唯一性保证

3. **地理位置查询**：
   - 通过 `(latitude, longitude)` 索引支持地图视图
   - 支持按地理位置聚合和筛选

---

## 查询优化策略

### 1. Merged Asset 视图

使用 SQL 视图合并本地和远程资产，提供统一的资产查询接口。

**查询逻辑**：
1. 查询远程资产（未删除、时间线可见、用户相关）
2. 处理堆叠（只显示主资产）
3. UNION ALL 本地资产（未同步到服务器、在选中相册中、不在排除相册中）
4. 按创建时间倒序排序

**优化点**：
- 使用 UNION ALL 避免去重开销
- 子查询优化本地资产关联
- 条件索引支持高效过滤

### 2. 批量操作

使用 `batch()` 方法进行批量插入/更新，减少事务开销：

```dart
await db.batch((batch) {
  for (final asset in assets) {
    batch.insert(db.remoteAssetEntity, asset);
  }
});
```

### 3. 流式查询

使用 `watch()` 方法实现实时数据更新：

```dart
db.remoteAssetEntity
  .select()
  .where((t) => t.ownerId.equals(userId))
  .watch()
  .listen((assets) {
    // 数据自动更新
  });
```

### 4. 分页查询

使用 `LIMIT` 和 `OFFSET` 实现分页，避免一次性加载大量数据。

---

## 数据迁移方案

### 版本化迁移

数据库使用版本化迁移策略，每个版本定义明确的迁移步骤。

**当前版本**：13

**迁移流程**：
1. 检测当前数据库版本
2. 从当前版本逐步升级到目标版本
3. 每个版本执行对应的迁移步骤
4. 迁移过程中关闭外键约束
5. 迁移完成后重新启用外键约束
6. 调试模式下检查外键完整性

### 主要迁移历史

**v1 → v2**：重构表结构，删除并重建所有表

**v2 → v3**：移除堆叠表的外键约束（改为应用层控制）

**v3 → v4**：添加人脸识别表，移除人物表的缩略图字段

**v4 → v5**：添加用户头像相关字段

**v5 → v6**：
- 调整远程资产唯一索引顺序
- 添加 `libraryId` 字段支持多库
- 更新唯一索引支持多库场景

**v6 → v7**：添加地理位置索引

**v7 → v8**：添加键值存储表

**v8 → v9**：添加本地相册关联远程相册字段

**v9 → v10**：
- 添加认证用户表
- 添加用户头像颜色字段

**v10 → v11**：添加本地相册-资产关联表的标记字段

**v11 → v12**：时间戳时区转换（本地时间 → UTC）

**v12 → v13**：
- 添加已删除本地资产表
- 添加相关索引

### 迁移最佳实践

1. **向后兼容**：新字段使用可空类型或提供默认值
2. **数据转换**：使用 `columnTransformer` 进行数据格式转换
3. **索引管理**：先删除旧索引，再创建新索引
4. **外键处理**：迁移时关闭外键，完成后重新启用
5. **测试验证**：调试模式下自动检查外键完整性

---

## 最佳实践

### 1. 表设计

- ✅ 使用业务主键（String），不使用自增 ID
- ✅ 启用 `STRICT` 模式保证类型安全
- ✅ 使用 `WITHOUT ROWID` 提升性能
- ✅ 为时间字段提供默认值
- ✅ 合理使用可空字段

### 2. 关系设计

- ✅ 使用外键约束保证数据完整性
- ✅ 合理选择删除策略（CASCADE/SET NULL）
- ✅ 避免循环依赖
- ✅ 使用复合主键表示多对多关系

### 3. 索引设计

- ✅ 为常用查询字段创建索引
- ✅ 使用复合索引优化多字段查询
- ✅ 使用条件索引优化特定场景
- ✅ 避免过度索引（影响写入性能）

### 4. 查询优化

- ✅ 使用批量操作减少事务开销
- ✅ 使用流式查询实现实时更新
- ✅ 使用分页避免一次性加载大量数据
- ✅ 利用索引优化查询性能

### 5. 数据迁移

- ✅ 版本化迁移，每个版本明确迁移步骤
- ✅ 保持向后兼容
- ✅ 迁移前备份数据
- ✅ 测试迁移脚本

### 6. 性能优化

- ✅ 使用 WAL 模式提升并发性能
- ✅ 合理设置 `busy_timeout` 避免并发冲突
- ✅ 使用 `batch()` 进行批量操作
- ✅ 避免在循环中执行数据库操作

### 7. 数据一致性

- ✅ 启用外键约束
- ✅ 使用事务保证原子性
- ✅ 软删除使用 `deletedAt` 字段
- ✅ 定期检查数据完整性

---

## 总结

Immich 移动端的 Drift 数据库架构设计遵循以下核心原则：

1. **清晰的数据分离**：本地和远程数据分别存储，通过 `checksum` 关联
2. **严格的数据完整性**：完整的外键约束和删除策略
3. **高效的查询性能**：合理的索引设计和查询优化
4. **灵活的扩展性**：版本化迁移支持渐进式升级
5. **良好的实践**：遵循 SQLite 和 Drift 最佳实践

该架构设计适用于需要处理大量媒体文件、支持多用户、需要离线功能的移动应用场景。通过合理的表设计、索引优化和查询策略，能够在保证数据一致性的同时，提供良好的性能和用户体验。

