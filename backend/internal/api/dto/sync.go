package dto

import "time"

// SyncRequestType identifies a sync stream kind.
type SyncRequestType string

const (
	SyncRequestTypeAssetsV1 SyncRequestType = "assets_v1"
)

// SyncStreamRequest is the body for POST /sync/assets/stream.
type SyncStreamRequest struct {
	Types       []SyncRequestType `json:"types" binding:"required,min=1"`
	Reset       bool              `json:"reset"`
	UpdatedAfter *string           `json:"updated_after,omitempty"` // RFC3339 timestamp
}

// CheckpointDto is one persisted sync checkpoint.
type CheckpointDto struct {
	Type string `json:"type"` // Sync type (e.g. "assets_v1")
	Ack  string `json:"ack"`  // Checkpoint ID
}

// GetCheckpointResponse lists checkpoints for the device.
type GetCheckpointResponse struct {
	Checkpoints []CheckpointDto `json:"checkpoints"`
}

// SetCheckpointRequest upserts one or more checkpoints.
type SetCheckpointRequest struct {
	Checkpoints []CheckpointDto `json:"checkpoints" binding:"required,min=1"`
}

// DeleteCheckpointRequest selects checkpoint types to delete.
type DeleteCheckpointRequest struct {
	Types []string `json:"types" binding:"required,min=1"` // Sync types to clear
}

// SyncAssetsResponse is a cursor-paged full sync payload (legacy/non-stream).
type SyncAssetsResponse struct {
	Assets     []*MediaResponse `json:"assets"`
	NextLastID string           `json:"next_last_id"`
	HasMore    bool             `json:"has_more"`
}

// ParseUpdatedAfter parses the optional updated_after timestamp.
func (r *SyncStreamRequest) ParseUpdatedAfter() (*time.Time, error) {
	if r.UpdatedAfter == nil || *r.UpdatedAfter == "" {
		return nil, nil
	}
	t, err := time.Parse(time.RFC3339, *r.UpdatedAfter)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

