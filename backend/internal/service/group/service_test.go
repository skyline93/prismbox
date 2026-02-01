package group

import (
	"context"
	"testing"

	"github.com/album/backend/internal/database/models"
	"github.com/album/backend/internal/repository"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func setupGetMyFeedTestDB(t *testing.T) *gorm.DB {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		t.Fatalf("open sqlite: %v", err)
	}
	err = db.AutoMigrate(
		&models.User{},
		&models.Group{},
		&models.GroupMember{},
		&models.GroupPost{},
		&models.GroupMedia{},
		&models.Media{},
		&models.Comment{},
		&models.Like{},
		&models.GroupInvite{},
	)
	if err != nil {
		t.Fatalf("migrate: %v", err)
	}
	return db
}

// TestGetMyFeed_EmptyGroups 无圈子时返回空 Feed
func TestGetMyFeed_EmptyGroups(t *testing.T) {
	db := setupGetMyFeedTestDB(t)
	ctx := context.Background()

	user := &models.User{Email: "u@test.com", Username: "u"}
	if err := db.WithContext(ctx).Create(user).Error; err != nil {
		t.Fatalf("create user: %v", err)
	}

	svc := NewService(
		db,
		repository.NewGroupRepository(db),
		repository.NewGroupMemberRepository(db),
		repository.NewGroupPostRepository(db),
		repository.NewGroupMediaRepository(db),
		repository.NewCommentRepository(db),
		repository.NewLikeRepository(db),
		repository.NewGroupInviteRepository(db),
		repository.NewMediaRepository(db),
		"",
		nil,
	)

	result, err := svc.GetMyFeed(ctx, user.ID, 1, 20)
	if err != nil {
		t.Fatalf("GetMyFeed: %v", err)
	}
	if result.Total != 0 || len(result.Posts) != 0 {
		t.Errorf("want empty feed, got total=%d posts=%d", result.Total, len(result.Posts))
	}
	if result.Page != 1 || result.Limit != 20 {
		t.Errorf("want page=1 limit=20, got page=%d limit=%d", result.Page, result.Limit)
	}
}

// TestGetMyFeed_WithPosts 仅限成员圈子，且每条帖子带 group_uuid、group_name
func TestGetMyFeed_WithPosts(t *testing.T) {
	db := setupGetMyFeedTestDB(t)
	ctx := context.Background()

	user := &models.User{Email: "u@test.com", Username: "u"}
	if err := db.WithContext(ctx).Create(user).Error; err != nil {
		t.Fatalf("create user: %v", err)
	}

	g1 := &models.Group{UUID: "g1-uuid", Name: "圈子1", OwnerID: user.ID}
	g2 := &models.Group{UUID: "g2-uuid", Name: "圈子2", OwnerID: user.ID}
	if err := db.WithContext(ctx).Create(g1).Error; err != nil {
		t.Fatalf("create g1: %v", err)
	}
	if err := db.WithContext(ctx).Create(g2).Error; err != nil {
		t.Fatalf("create g2: %v", err)
	}

	// 用户只加入 g1、g2（成员）
	if err := db.WithContext(ctx).Create(&models.GroupMember{GroupID: g1.ID, UserID: user.ID, Role: models.RoleOwner}).Error; err != nil {
		t.Fatalf("create member g1: %v", err)
	}
	if err := db.WithContext(ctx).Create(&models.GroupMember{GroupID: g2.ID, UserID: user.ID, Role: models.RoleMember}).Error; err != nil {
		t.Fatalf("create member g2: %v", err)
	}

	// 两个圈子各一条帖子
	if err := db.WithContext(ctx).Create(&models.GroupPost{GroupID: g1.ID, CreatorID: user.ID, Caption: "post1"}).Error; err != nil {
		t.Fatalf("create post1: %v", err)
	}
	if err := db.WithContext(ctx).Create(&models.GroupPost{GroupID: g2.ID, CreatorID: user.ID, Caption: "post2"}).Error; err != nil {
		t.Fatalf("create post2: %v", err)
	}

	svc := NewService(
		db,
		repository.NewGroupRepository(db),
		repository.NewGroupMemberRepository(db),
		repository.NewGroupPostRepository(db),
		repository.NewGroupMediaRepository(db),
		repository.NewCommentRepository(db),
		repository.NewLikeRepository(db),
		repository.NewGroupInviteRepository(db),
		repository.NewMediaRepository(db),
		"",
		nil,
	)

	result, err := svc.GetMyFeed(ctx, user.ID, 1, 20)
	if err != nil {
		t.Fatalf("GetMyFeed: %v", err)
	}
	if result.Total != 2 || len(result.Posts) != 2 {
		t.Errorf("want 2 posts, got total=%d len=%d", result.Total, len(result.Posts))
	}
	for i, p := range result.Posts {
		if p.GroupUUID == "" || p.GroupName == "" {
			t.Errorf("post[%d] missing group_uuid or group_name", i)
		}
	}
	// 应包含来自 g1 和 g2 的帖子
	seen := make(map[string]bool)
	for _, p := range result.Posts {
		seen[p.GroupUUID] = true
	}
	if !seen["g1-uuid"] || !seen["g2-uuid"] {
		t.Errorf("feed should contain posts from both groups, got group_uuids: %v", seen)
	}
}
