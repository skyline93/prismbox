# 数据库迁移：添加 thumb_hash 字段

## 迁移说明

此迁移为 `medias` 表添加 `thumb_hash` 字段，用于存储 ThumbHash 占位符数据。

## 迁移内容

### SQL 迁移脚本

```sql
-- 为 medias 表添加 thumb_hash 字段
ALTER TABLE medias ADD COLUMN thumb_hash VARCHAR(200) NULL;
```

### 字段说明

- **字段名**: `thumb_hash`
- **类型**: `VARCHAR(200)`
- **可空**: `YES` (允许 NULL，因为历史数据可能没有 ThumbHash)
- **说明**: 存储 base64 编码的 ThumbHash 占位符，约 100-150 字符

## 自动迁移

由于项目使用 GORM 的 `AutoMigrate` 机制，`medias` 表的模型定义（`internal/database/models/media.go`）中已包含 `ThumbHash` 字段：

```go
type Media struct {
    // ... 其他字段
    ThumbHash string `gorm:"type:varchar(200)"` // base64 编码的 ThumbHash
}
```

当应用启动时，GORM 会自动检测模型变化并执行迁移，无需手动执行 SQL 脚本。

## 验证迁移

迁移完成后，可以通过以下方式验证：

```sql
-- 检查字段是否存在
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'medias' AND column_name = 'thumb_hash';

-- 检查字段数据
SELECT uuid, thumb_hash FROM medias WHERE thumb_hash IS NOT NULL LIMIT 10;
```

## 回滚（如需要）

如果需要回滚此迁移：

```sql
ALTER TABLE medias DROP COLUMN thumb_hash;
```

**注意**: 回滚会丢失所有 ThumbHash 数据，请谨慎操作。

## 历史数据迁移

对于已存在的媒体数据，ThumbHash 会在以下时机自动生成：

1. **新上传的媒体**: 在后台 Worker 处理时自动生成
2. **历史数据**: 可以通过后台任务批量生成（可选）

批量生成脚本示例（需要实现）：

```go
// 批量生成历史数据的 ThumbHash
func BatchGenerateThumbHash(ctx context.Context, repo repository.MediaRepository) error {
    // 查询所有没有 ThumbHash 的图片
    medias, err := repo.FindWithoutThumbHash(ctx)
    // ... 生成逻辑
}
```

## 相关文档

- 媒体资源优化中期方案文档：`doc/媒体资源优化中期方案文档（基于现有存储系统）.md`
- Media 模型定义：`internal/database/models/media.go`
- ThumbHash 生成器：`internal/thumbhash/generator.go`

