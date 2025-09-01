// server/handlers/group/post_handler.go

package group

import (
	"server/core"
	"server/handlers"
	"server/models"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// CreatePostInput 定义了创建帖子时的输入结构
type CreatePostInput struct {
	MediaUUIDs []string `json:"media_uuids" binding:"required,min=1"`
	Caption    string   `json:"caption"`
}

// CreatePost godoc
// @Summary      在圈子中创建新帖子
// @Description  发布一个包含一个或多个媒体文件的新帖子到指定圈子
// @Tags         Groups
// @Accept       json
// @Produce      json
// @Param        uuid path string true "圈子的UUID" format(uuid)
// @Param        input body CreatePostInput true "帖子的内容，包含媒体UUID列表和说明"
// @Success      201  {object}  core.ApiResponse{data=models.GroupPost} "帖子创建成功"
// @Failure      400  {object}  core.ApiResponse "请求参数错误"
// @Failure      403  {object}  core.ApiResponse "无权限操作（非圈子成员）"
// @Security     BearerAuth
// @Router       /groups/{uuid}/posts [post]
func (h *GroupHandler) CreatePost(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	groupUUID := c.Param("uuid")

	// 1. 权限校验 (使用新定义的辅助函数)
	group, err := h.getGroupAndCheckMembership(groupUUID, userID)
	if err != nil {
		core.Error(c, err.Error())
		return
	}

	// 2. 绑定和验证输入
	var input CreatePostInput
	if err := c.ShouldBindJSON(&input); err != nil {
		core.Error(c, "Invalid input: "+err.Error())
		return
	}

	// 3. 校验媒体所有权
	var userMedia []models.Media
	if err := h.DB.Where("uuid IN ? AND user_id = ?", input.MediaUUIDs, userID).Find(&userMedia).Error; err != nil {
		core.Error(c, "Failed to verify media ownership")
		return
	}
	if len(userMedia) != len(input.MediaUUIDs) {
		core.Error(c, "Some media were not found or you do not have permission to share them")
		return
	}

	// 4. 使用事务创建帖子和关联的媒体记录
	var createdPost models.GroupPost
	err = h.DB.Transaction(func(tx *gorm.DB) error {
		// a. 创建 GroupPost
		post := models.GroupPost{
			GroupID:   group.ID,
			CreatorID: userID,
			Caption:   input.Caption,
		}
		if err := tx.Create(&post).Error; err != nil {
			return err
		}

		// b. 准备并插入 GroupMedia 记录
		var groupMediaRecords []models.GroupMedia
		for _, media := range userMedia {
			groupMediaRecords = append(groupMediaRecords, models.GroupMedia{
				GroupID:   group.ID,
				PostID:    post.ID, // 关联到新创建的帖子
				MediaUUID: media.UUID,
			})
		}
		if err := tx.Create(&groupMediaRecords).Error; err != nil {
			return err
		}

		// c. 预加载数据以便返回给前端
		if err := tx.Preload("Creator").First(&post, post.ID).Error; err != nil {
			return err
		}
		createdPost = post
		return nil
	})

	if err != nil {
		core.Error(c, "Failed to create post: "+err.Error())
		return
	}

	core.Success(c, "Post created successfully", createdPost)
}

// GroupPostResponse 是为 Feed 流定制的响应结构
type GroupPostResponse struct {
	ID            uint                        `json:"id"`
	Caption       string                      `json:"caption"`
	CreatedAt     time.Time                   `json:"created_at"`
	Creator       handlers.UserSimpleResponse `json:"creator"`
	Media         []handlers.MediaResponse    `json:"media"`
	LikesCount    int64                       `json:"likes_count"`
	CommentsCount int64                       `json:"comments_count"`
	// HasLiked      bool                        `json:"has_liked"` // 可选：当前用户是否已点赞
}

// GetGroupFeed godoc
// @Summary      获取圈子 Feed 流 (新版)
// @Description  分页获取圈子中的帖子，按创建时间倒序排列
// @Tags         Groups
// @Produce      json
// @Param        uuid path string true "圈子的UUID" format(uuid)
// @Param        page query int false "页码" default(1)
// @Param        limit query int false "每页数量" default(20)
// @Success      200  {object}  core.ApiResponse{data=[]GroupPostResponse} "成功获取Feed流"
// @Failure      403  {object}  core.ApiResponse "无权限操作（非圈子成员）"
// @Security     BearerAuth
// @Router       /groups/{uuid}/feed [get]
func (h *GroupHandler) GetGroupFeed(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	groupUUID := c.Param("uuid")

	// 1. 权限校验
	group, err := h.getGroupAndCheckMembership(groupUUID, userID)
	if err != nil {
		core.Error(c, err.Error())
		return
	}

	// 2. 分页参数 (使用新定义的辅助函数)
	_, limit, offset := core.GetPaginationParams(c)

	// 3. 查询帖子列表，并预加载创建者信息
	var posts []models.GroupPost
	err = h.DB.Model(&models.GroupPost{}).
		Where("group_id = ?", group.ID).
		Preload("Creator").
		Order("created_at desc").
		Limit(limit).
		Offset(offset).
		Find(&posts).Error

	if err != nil {
		core.Error(c, "Failed to fetch group feed")
		return
	}
	if len(posts) == 0 {
		core.Success(c, "Feed is empty", []interface{}{})
		return
	}

	// 4. 批量处理和组装响应
	postIDs := make([]uint, len(posts))
	for i, p := range posts {
		postIDs[i] = p.ID
	}

	var allGroupMedia []models.GroupMedia
	h.DB.Where("post_id IN ?", postIDs).Find(&allGroupMedia)

	mediaUUIDs := make([]string, 0, len(allGroupMedia))
	for _, gm := range allGroupMedia {
		mediaUUIDs = append(mediaUUIDs, gm.MediaUUID)
	}

	// c. 批量获取所有媒体的详细信息 (使用新定义的辅助函数)
	mediaDetailsMap := handlers.GetMediaDetailsMap(h.DB, mediaUUIDs)

	// d. 批量获取点赞和评论数
	likesCountMap := getCountsMap(h.DB.Model(&models.Like{}), "post_id", postIDs)
	commentsCountMap := getCountsMap(h.DB.Model(&models.Comment{}), "post_id", postIDs)

	// e. 组装最终响应
	response := make([]GroupPostResponse, len(posts))
	postMediaMap := make(map[uint][]handlers.MediaResponse)

	for _, gm := range allGroupMedia {
		if detail, ok := mediaDetailsMap[gm.MediaUUID]; ok {
			postMediaMap[gm.PostID] = append(postMediaMap[gm.PostID], detail)
		}
	}

	for i, post := range posts {
		response[i] = GroupPostResponse{
			ID:            post.ID,
			Caption:       post.Caption,
			CreatedAt:     post.CreatedAt,
			Creator:       handlers.ToUserSimpleResponse(post.Creator), // 使用新定义的转换函数
			Media:         postMediaMap[post.ID],
			LikesCount:    likesCountMap[post.ID],
			CommentsCount: commentsCountMap[post.ID],
		}
	}

	core.Success(c, "Feed retrieved successfully", response)
}

// 辅助函数：批量获取计数
func getCountsMap(db *gorm.DB, fieldName string, ids []uint) map[uint]int64 {
	type Result struct {
		ID    uint  `gorm:"column:id"`
		Total int64 `gorm:"column:total"`
	}
	var results []Result

	if len(ids) == 0 {
		return make(map[uint]int64)
	}

	db.Select(fieldName+" as id, count(*) as total").
		Where(fieldName+" IN ?", ids).
		Group(fieldName).
		Scan(&results)

	countsMap := make(map[uint]int64)
	for _, res := range results {
		countsMap[res.ID] = res.Total
	}
	return countsMap
}
