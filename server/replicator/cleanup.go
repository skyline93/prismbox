// replicator/cleanup.go

package replicator

import (
	"log"
	"time"

	"gorm.io/gorm"
)

// cleanupService 负责清理陈旧的同步日志。这是一个内部结构体。
type cleanupService struct {
	db     *gorm.DB
	config *Config
}

func newCleanupService(db *gorm.DB, config *Config) *cleanupService {
	return &cleanupService{db: db, config: config}
}

func (s *cleanupService) start() {
	ticker := time.NewTicker(s.config.CleanupInterval)
	go func() {
		for range ticker.C {
			log.Println("Running changelog cleanup job...")
			if err := s.runCleanup(); err != nil {
				log.Printf("Changelog cleanup job failed: %v", err)
			}
		}
	}()
}

func (s *cleanupService) runCleanup() error {
	var minSeqID int64
	activeThreshold := time.Now().UTC().Add(-s.config.DeviceActiveThreshold)

	err := s.db.Model(&ClientSyncStatus{}).
		Where("last_seen_timestamp > ?", activeThreshold).
		Select("COALESCE(MIN(last_synced_sequence_id), 0)").
		Row().Scan(&minSeqID)
	if err != nil {
		return err
	}

	if minSeqID > 0 {
		res := s.db.Where("sequence_id < ?", minSeqID).Delete(&Changelog{})
		if res.Error != nil {
			return res.Error
		}
		log.Printf("Changelog cleanup successful. Deleted %d rows older than sequence_id %d.", res.RowsAffected, minSeqID)
	} else {
		log.Println("No active clients found or min sequence_id is 0. Skipping cleanup.")
	}

	return nil
}
