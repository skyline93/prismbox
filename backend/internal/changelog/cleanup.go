package changelog

import (
	"time"

	"github.com/album/backend/pkg/logger"
	"gorm.io/gorm"
)

// cleanupService 负责清理陈旧的变更日志
type cleanupService struct {
	db     *gorm.DB
	config *Config
	log    logger.Logger
}

func newCleanupService(db *gorm.DB, config *Config) *cleanupService {
	return &cleanupService{
		db:     db,
		config: config,
		log:    logger.New("changelog.cleanup"),
	}
}

func (s *cleanupService) start() {
	ticker := time.NewTicker(s.config.CleanupInterval)
	go func() {
		for range ticker.C {
			s.log.Info("Running changelog cleanup job...")
			if err := s.runCleanup(); err != nil {
				s.log.Error("Changelog cleanup job failed",
					logger.Error(err),
				)
			}
		}
	}()
}

func (s *cleanupService) runCleanup() error {
	var minSeqID int64
	activeThreshold := time.Now().UTC().Add(-s.config.DeviceActiveThreshold)

	err := s.db.Model(&ClientChangelogStatus{}).
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
		s.log.Info("Changelog cleanup successful",
			logger.Int64("deleted_rows", res.RowsAffected),
			logger.Int64("min_sequence_id", minSeqID),
		)
	} else {
		s.log.Info("No active clients found or min sequence_id is 0. Skipping cleanup.")
	}

	return nil
}
