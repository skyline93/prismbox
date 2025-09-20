// replicator/sync_handler.go

package replicator

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// --- HTTP Handler ---

// SyncHandler 封装了与同步相关的 API 接口。这是一个内部结构体。
type syncHandler struct {
	service *syncService
	config  *Config
}

func newSyncHandler(service *syncService, config *Config) *syncHandler {
	return &syncHandler{service: service, config: config}
}

func (h *syncHandler) registerRoutes(router *gin.RouterGroup) {
	syncGroup := router.Group("/sync")
	{
		syncGroup.GET("", h.handleSync)
		syncGroup.GET("/full_init", h.handleFullSyncInit)
		syncGroup.GET("/full_data", h.handleFullSyncData)
	}
}

func (h *syncHandler) handleSync(c *gin.Context) {
	userID := c.GetHeader("X-User-ID")
	deviceID := c.GetHeader("X-Device-ID")
	if userID == "" || deviceID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "X-User-ID and X-Device-ID headers are required"})
		return
	}
	lastSeqID, _ := strconv.ParseInt(c.Query("last_seq_id"), 10, 64)
	limit, err := strconv.Atoi(c.DefaultQuery("limit", strconv.Itoa(h.config.DefaultSyncPageLimit)))
	if err != nil || limit <= 0 {
		limit = h.config.DefaultSyncPageLimit
	}
	changes, latestSeqID, hasMore, err := h.service.GetIncrementalChanges(lastSeqID, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch changes"})
		return
	}
	go h.service.UpdateClientStatus(deviceID, userID, latestSeqID)
	c.JSON(http.StatusOK, gin.H{"changes": changes, "latest_seq_id": latestSeqID, "has_more": hasMore})
}

func (h *syncHandler) handleFullSyncInit(c *gin.Context) {
	tables, snapshotSeqID, err := h.service.GetFullSyncSnapshotInfo()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get snapshot info"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"tables_to_sync": tables, "snapshot_seq_id": snapshotSeqID})
}

func (h *syncHandler) handleFullSyncData(c *gin.Context) {
	tableName := c.Query("table")
	if tableName == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "table query parameter is required"})
		return
	}
	limit, err := strconv.Atoi(c.DefaultQuery("limit", strconv.Itoa(h.config.DefaultSyncPageLimit)))
	if err != nil || limit <= 0 {
		limit = h.config.DefaultSyncPageLimit
	}
	pageToken := c.Query("page_token")
	changes, nextToken, err := h.service.GetFullSyncDataForTable(tableName, pageToken, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch full data"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"changes": changes, "next_page_token": nextToken})
}

// --- Sync Service Logic ---

// syncService 提供了同步所需的核心业务逻辑。这是一个内部结构体。
type syncService struct {
	db     *gorm.DB
	config *Config
}

func newSyncService(db *gorm.DB, config *Config) *syncService {
	return &syncService{db: db, config: config}
}

func (s *syncService) GetIncrementalChanges(lastSeqID int64, limit int) ([]Changelog, int64, bool, error) {
	var changes []Changelog
	if err := s.db.Where("sequence_id > ?", lastSeqID).Order("sequence_id asc").Limit(limit).Find(&changes).Error; err != nil {
		return nil, 0, false, err
	}
	var latestSeqID int64 = lastSeqID
	if len(changes) > 0 {
		latestSeqID = changes[len(changes)-1].SequenceID
	}
	var count int64
	s.db.Model(&Changelog{}).Where("sequence_id > ?", latestSeqID).Count(&count)
	return changes, latestSeqID, count > 0, nil
}

func (s *syncService) GetFullSyncSnapshotInfo() ([]string, int64, error) {
	var maxSeqID int64
	err := s.db.Transaction(func(tx *gorm.DB) error {
		return tx.Model(&Changelog{}).Select("COALESCE(MAX(sequence_id), 0)").Row().Scan(&maxSeqID)
	})
	if err != nil {
		return nil, 0, err
	}
	tables := make([]string, 0, len(s.config.FullSyncTables))
	for table := range s.config.FullSyncTables {
		tables = append(tables, table)
	}
	return tables, maxSeqID, nil
}

func (s *syncService) GetFullSyncDataForTable(tableName, pageToken string, limit int) ([]Changelog, *string, error) {
	tableConfig, ok := s.config.FullSyncTables[tableName]
	if !ok {
		return nil, nil, fmt.Errorf("table '%s' is not configured for full sync", tableName)
	}

	var results []map[string]interface{}
	offset := 0
	if pageToken != "" {
		fmt.Sscanf(pageToken, "%d", &offset)
	}

	pkColumn := tableConfig.PrimaryKeyColumn
	query := s.db.Table(tableName).Order(fmt.Sprintf("%s asc", pkColumn)).Limit(limit).Offset(offset)
	if err := query.Find(&results).Error; err != nil {
		return nil, nil, err
	}

	changes := make([]Changelog, 0, len(results))
	for _, record := range results {
		payload, err := json.Marshal(record)
		if err != nil {
			continue
		}
		recordID := fmt.Sprintf("%v", record[pkColumn])
		changes = append(changes, Changelog{
			TableName:     tableName,
			RecordID:      recordID,
			OperationType: OperationCreated,
			Payload:       payload,
		})
	}

	var nextToken *string
	if len(results) == limit {
		t := fmt.Sprintf("%d", offset+limit)
		nextToken = &t
	}
	return changes, nextToken, nil
}

func (s *syncService) UpdateClientStatus(deviceID, userID string, lastSeqID int64) error {
	status := ClientSyncStatus{
		DeviceID:             deviceID,
		UserID:               userID,
		LastSyncedSequenceID: lastSeqID,
		LastSeenTimestamp:    time.Now().UTC(),
	}
	return s.db.Save(&status).Error
}
