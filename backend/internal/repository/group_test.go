package repository

import (
	"context"
	"testing"
	"time"

	"github.com/album/backend/internal/database/models"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func setupGroupPostTestDB(t *testing.T) *gorm.DB {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		t.Fatalf("open sqlite: %v", err)
	}
	if err := db.AutoMigrate(&models.User{}, &models.Group{}, &models.GroupPost{}); err != nil {
		t.Fatalf("migrate: %v", err)
	}
	return db
}

func TestFindByGroupIDs_EmptyIDs(t *testing.T) {
	db := setupGroupPostTestDB(t)
	repo := NewGroupPostRepository(db)
	ctx := context.Background()

	posts, err := repo.FindByGroupIDs(ctx, nil, 10, 0)
	if err != nil {
		t.Fatalf("FindByGroupIDs(nil): %v", err)
	}
	if posts != nil {
		t.Errorf("FindByGroupIDs(nil) want nil, got len=%d", len(posts))
	}

	posts, err = repo.FindByGroupIDs(ctx, []uint{}, 10, 0)
	if err != nil {
		t.Fatalf("FindByGroupIDs([]): %v", err)
	}
	if posts != nil {
		t.Errorf("FindByGroupIDs([]) want nil, got len=%d", len(posts))
	}
}

func TestFindByGroupIDs_OrderAndLimit(t *testing.T) {
	db := setupGroupPostTestDB(t)
	ctx := context.Background()

	user := &models.User{Email: "u@test.com", Username: "u"}
	if err := db.WithContext(ctx).Create(user).Error; err != nil {
		t.Fatalf("create user: %v", err)
	}

	g1 := &models.Group{UUID: "g1-uuid", Name: "G1", OwnerID: user.ID}
	g2 := &models.Group{UUID: "g2-uuid", Name: "G2", OwnerID: user.ID}
	if err := db.WithContext(ctx).Create(g1).Error; err != nil {
		t.Fatalf("create g1: %v", err)
	}
	if err := db.WithContext(ctx).Create(g2).Error; err != nil {
		t.Fatalf("create g2: %v", err)
	}

	base := time.Now().Add(-1 * time.Hour)
	for i := 0; i < 5; i++ {
		created := base.Add(time.Duration(i) * time.Minute)
		post := &models.GroupPost{
			GroupID:   g1.ID,
			CreatorID: user.ID,
			Caption:   "p1",
		}
		post.CreatedAt = created
		if err := db.WithContext(ctx).Create(post).Error; err != nil {
			t.Fatalf("create post: %v", err)
		}
	}
	for i := 0; i < 3; i++ {
		created := base.Add(time.Duration(i+10) * time.Minute)
		post := &models.GroupPost{
			GroupID:   g2.ID,
			CreatorID: user.ID,
			Caption:   "p2",
		}
		post.CreatedAt = created
		if err := db.WithContext(ctx).Create(post).Error; err != nil {
			t.Fatalf("create post: %v", err)
		}
	}

	repo := NewGroupPostRepository(db)
	groupIDs := []uint{g1.ID, g2.ID}

	// limit 2, offset 0: 应返回按 created_at DESC 的前 2 条
	posts, err := repo.FindByGroupIDs(ctx, groupIDs, 2, 0)
	if err != nil {
		t.Fatalf("FindByGroupIDs: %v", err)
	}
	if len(posts) != 2 {
		t.Errorf("want 2 posts, got %d", len(posts))
	}
	// 最新的一条应在前
	if posts[0].CreatedAt.Before(posts[1].CreatedAt) {
		t.Error("posts should be ordered by created_at DESC")
	}

	// limit 3, offset 2
	posts2, err := repo.FindByGroupIDs(ctx, groupIDs, 3, 2)
	if err != nil {
		t.Fatalf("FindByGroupIDs offset: %v", err)
	}
	if len(posts2) != 3 {
		t.Errorf("want 3 posts, got %d", len(posts2))
	}
}
