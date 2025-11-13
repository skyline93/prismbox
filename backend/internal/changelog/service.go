package changelog

import (
	"encoding/json"
	"fmt"
	"time"

	"gorm.io/gorm"
)

// ChangelogQuery 变更日志查询条件
type ChangelogQuery struct {
	// IsolationKey 隔离键，如 "user_id", "organization_id" 等
	IsolationKey string

	// IsolationValue 隔离值，如用户ID、组织ID等
	IsolationValue string

	// TableName 表名（可选，用于过滤特定表）
	TableName string
}

// changelogService 提供了变更日志所需的核心业务逻辑
type changelogService struct {
	db     *gorm.DB
	config *Config
}

func newChangelogService(db *gorm.DB, config *Config) *changelogService {
	return &changelogService{db: db, config: config}
}

// GetIncrementalChanges 获取增量变更
func (s *changelogService) GetIncrementalChanges(
	query *ChangelogQuery,
	lastSeqID int64,
	limit int,
) ([]Changelog, int64, bool, error) {
	var changes []Changelog

	dbQuery := s.db.Where("sequence_id > ?", lastSeqID)

	// 应用隔离条件
	if query.IsolationKey != "" && query.IsolationValue != "" {
		dbQuery = dbQuery.Where("isolation_key = ? AND isolation_value = ?",
			query.IsolationKey, query.IsolationValue)
	}

	// 应用表名过滤
	if query.TableName != "" {
		dbQuery = dbQuery.Where("table_name = ?", query.TableName)
	}

	// 执行查询
	if err := dbQuery.Order("sequence_id asc").Limit(limit).Find(&changes).Error; err != nil {
		return nil, 0, false, err
	}

	var latestSeqID int64 = lastSeqID
	if len(changes) > 0 {
		latestSeqID = changes[len(changes)-1].SequenceID
	}

	// 检查是否还有更多数据
	countQuery := s.db.Model(&Changelog{}).Where("sequence_id > ?", latestSeqID)
	if query.IsolationKey != "" && query.IsolationValue != "" {
		countQuery = countQuery.Where("isolation_key = ? AND isolation_value = ?",
			query.IsolationKey, query.IsolationValue)
	}
	if query.TableName != "" {
		countQuery = countQuery.Where("table_name = ?", query.TableName)
	}

	var count int64
	countQuery.Count(&count)

	return changes, latestSeqID, count > 0, nil
}

// GetFullChangelogSnapshotInfo 获取全量变更日志快照信息
func (s *changelogService) GetFullChangelogSnapshotInfo() ([]string, int64, error) {
	var maxSeqID int64
	err := s.db.Transaction(func(tx *gorm.DB) error {
		return tx.Model(&Changelog{}).Select("COALESCE(MAX(sequence_id), 0)").Row().Scan(&maxSeqID)
	})
	if err != nil {
		return nil, 0, err
	}

	tables := make([]string, 0, len(s.config.FullChangelogTables))
	for table := range s.config.FullChangelogTables {
		tables = append(tables, table)
	}

	return tables, maxSeqID, nil
}

// GetFullChangelogDataForTable 获取全量变更日志数据
func (s *changelogService) GetFullChangelogDataForTable(
	query *ChangelogQuery,
	tableName, pageToken string,
	limit int,
) ([]Changelog, *string, error) {
	tableConfig, ok := s.config.FullChangelogTables[tableName]
	if !ok {
		return nil, nil, fmt.Errorf("table '%s' is not configured for full changelog", tableName)
	}

	var results []map[string]interface{}
	offset := 0
	if pageToken != "" {
		fmt.Sscanf(pageToken, "%d", &offset)
	}

	pkColumn := tableConfig.PrimaryKeyColumn
	dbQuery := s.db.Table(tableName).Order(fmt.Sprintf("%s asc", pkColumn)).Limit(limit).Offset(offset)

	// 应用隔离条件（从业务表查询）
	if query.IsolationKey != "" && query.IsolationValue != "" {
		dbQuery = dbQuery.Where(fmt.Sprintf("%s = ?", query.IsolationKey), query.IsolationValue)
	}

	if err := dbQuery.Find(&results).Error; err != nil {
		return nil, nil, err
	}

	changes := make([]Changelog, 0, len(results))
	for _, record := range results {
		payload, err := json.Marshal(record)
		if err != nil {
			continue
		}

		recordID := fmt.Sprintf("%v", record[pkColumn])
		changelog := Changelog{
			TableNameCol:   tableName,
			RecordID:       recordID,
			OperationType:  OperationCreated,
			Payload:        JSON(payload),
			Timestamp:      time.Now().UTC(),
			IsolationKey:   query.IsolationKey,
			IsolationValue: query.IsolationValue,
		}

		changes = append(changes, changelog)
	}

	var nextToken *string
	if len(results) == limit {
		t := fmt.Sprintf("%d", offset+limit)
		nextToken = &t
	}

	return changes, nextToken, nil
}

// UpdateClientStatus 更新客户端变更日志同步状态
func (s *changelogService) UpdateClientStatus(deviceID, userID string, lastSeqID int64) error {
	status := ClientChangelogStatus{
		DeviceID:                deviceID,
		UserID:                  userID,
		LastChangelogSequenceID: lastSeqID,
		LastSeenTimestamp:       time.Now().UTC(),
	}
	return s.db.Save(&status).Error
}
