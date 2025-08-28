// server/handlers/group_handler.go

package handlers

// import (
// 	"errors"
// 	"math/rand"
// 	"server/core"
// 	"server/models"
// 	"strconv"
// 	"time"

// 	"github.com/gin-gonic/gin"
// 	"github.com/google/uuid"
// 	"gorm.io/gorm"
// )

// // GroupHandler 封装了所有与圈子相关的HTTP处理器
// type GroupHandler struct {
// 	DB *gorm.DB
// }

// // --- DTOs (Data Transfer Objects) ---

// // CreateGroupInput 定义了创建圈子的请求体结构
// type CreateGroupInput struct {
// 	Name        string `json:"name" binding:"required" example:"巴厘岛假日"`
// 	Description string `json:"description" example:"2025年的家庭旅行"`
// }

// // UpdateGroupInput 定义了更新圈子信息的请求体结构
// type UpdateGroupInput struct {
// 	Name        *string `json:"name" example:"巴厘岛假日 updated"`
// 	Description *string `json:"description" example:"2025年最棒的家庭旅行"`
// }

// // GroupMemberResponse 定义了获取圈子成员列表时的响应结构，过滤了敏感信息
// type GroupMemberResponse struct {
// 	UserID   uint             `json:"user_id"`
// 	Username string           `json:"username"`
// 	Role     models.GroupRole `json:"role"`
// 	JoinedAt time.Time        `json:"joined_at"`
// }

// type JoinGroupInput struct {
// 	Code string `json:"code" binding:"required" example:"A7B3D9K1"`
// }

// // ShareMediaInput 定义了分享媒体到圈子的请求体结构
// type ShareMediaInput struct {
// 	MediaUUIDs []string `json:"media_uuids" binding:"required"`
// 	Caption    string   `json:"caption,omitempty"`
// }

// // GroupFeedItemResponse 定义了圈子 Feed 流中单个媒体项的响应结构
// type GroupFeedItemResponse struct {
// 	GroupMediaID uint         `json:"group_media_id"`
// 	Caption      string       `json:"caption"`
// 	SharedAt     time.Time    `json:"shared_at"`
// 	Uploader     UploaderInfo `json:"uploader"`
// 	MediaDetails models.Media `json:"media_details"`
// }

// // UploaderInfo 嵌套在 GroupFeedItemResponse 中，用于表示上传者信息
// type UploaderInfo struct {
// 	UserID   uint   `json:"user_id"`
// 	Username string `json:"username"`
// }

// // CreateCommentInput 定义了创建评论的请求体结构
// type CreateCommentInput struct {
// 	Content string `json:"content" binding:"required"`
// }

// // CommentResponse 定义了获取评论列表时的响应结构
// type CommentResponse struct {
// 	ID        uint      `json:"id"`
// 	CreatedAt time.Time `json:"created_at"`
// 	Content   string    `json:"content"`
// 	User      UserInfo  `json:"user"`
// }

// // UserInfo 嵌套在 CommentResponse 中，用于表示评论者信息
// type UserInfo struct {
// 	UserID   uint   `json:"user_id"`
// 	Username string `json:"username"`
// }

// // --- Handler Methods ---

// // CreateGroup godoc
// // @Summary      创建新圈子
// // @Description  为当前登录的用户创建一个新的圈子，创建者自动成为“所有者”
// // @Tags         Groups
// // @Accept       json
// // @Produce      json
// // @Param        group body CreateGroupInput true "圈子信息"
// // @Success      200  {object}  core.ApiResponse{data=models.Group} "圈子创建成功"
// // @Failure      400  {object}  core.ApiResponse "请求参数错误或服务器内部错误"
// // @Security     BearerAuth
// // @Router       /groups [post]
// func (h *GroupHandler) CreateGroup(c *gin.Context) {
// 	userID := c.MustGet("userID").(uint)

// 	var input CreateGroupInput
// 	if err := c.ShouldBindJSON(&input); err != nil {
// 		core.Error(c, "Invalid input: "+err.Error())
// 		return
// 	}

// 	group := models.Group{
// 		UUID:        uuid.New().String(),
// 		Name:        input.Name,
// 		Description: input.Description,
// 		OwnerID:     userID,
// 	}

// 	// 使用事务确保数据一致性
// 	err := h.DB.Transaction(func(tx *gorm.DB) error {
// 		// 1. 创建圈子
// 		if err := tx.Create(&group).Error; err != nil {
// 			return err
// 		}

// 		// 2. 将创建者作为所有者添加到成员表
// 		member := models.GroupMember{
// 			GroupID: group.ID,
// 			UserID:  userID,
// 			Role:    models.RoleOwner,
// 		}
// 		if err := tx.Create(&member).Error; err != nil {
// 			return err
// 		}

// 		return nil
// 	})

// 	if err != nil {
// 		core.Error(c, "Failed to create group: "+err.Error())
// 		return
// 	}

// 	core.Success(c, "Group created successfully", group)
// }

// // GetMyGroups godoc
// // @Summary      获取我加入的圈子列表
// // @Description  获取当前用户加入的所有圈子列表
// // @Tags         Groups
// // @Produce      json
// // @Success      200  {object}  core.ApiResponse{data=[]models.Group} "成功获取圈子列表"
// // @Failure      400  {object}  core.ApiResponse "数据库错误"
// // @Security     BearerAuth
// // @Router       /groups [get]
// func (h *GroupHandler) GetMyGroups(c *gin.Context) {
// 	userID := c.MustGet("userID").(uint)

// 	var groups []models.Group
// 	err := h.DB.Joins("JOIN group_members on group_members.group_id = groups.id").
// 		Where("group_members.user_id = ?", userID).
// 		Order("groups.created_at desc").
// 		Find(&groups).Error

// 	if err != nil {
// 		core.Error(c, "Failed to fetch groups: "+err.Error())
// 		return
// 	}

// 	core.Success(c, "Groups retrieved successfully", groups)
// }

// // GetGroupDetails godoc
// // @Summary      获取圈子详情
// // @Description  获取单个圈子的详细信息，前提是当前用户是该圈子成员
// // @Tags         Groups
// // @Produce      json
// // @Param        uuid path string true "圈子的UUID" format(uuid)
// // @Success      200  {object}  core.ApiResponse{data=models.Group} "成功获取圈子详情"
// // @Failure      400  {object}  core.ApiResponse "圈子未找到或无权限"
// // @Security     BearerAuth
// // @Router       /groups/{uuid} [get]
// func (h *GroupHandler) GetGroupDetails(c *gin.Context) {
// 	userID := c.MustGet("userID").(uint)
// 	groupUUID := c.Param("uuid")

// 	// 权限校验：确保用户是圈子成员
// 	var member models.GroupMember
// 	err := h.DB.Joins("JOIN groups on groups.id = group_members.group_id").
// 		Where("groups.uuid = ? AND group_members.user_id = ?", groupUUID, userID).
// 		First(&member).Error
// 	if err != nil {
// 		core.Error(c, "Group not found or permission denied")
// 		return
// 	}

// 	var group models.Group
// 	if err := h.DB.First(&group, "uuid = ?", groupUUID).Error; err != nil {
// 		core.Error(c, "Group not found") // 理论上不会发生，因为上面已经校验过
// 		return
// 	}

// 	core.Success(c, "Group details retrieved successfully", group)
// }

// // UpdateGroup godoc
// // @Summary      更新圈子信息
// // @Description  更新圈子名称或描述，仅限圈主或管理员操作
// // @Tags         Groups
// // @Accept       json
// // @Produce      json
// // @Param        uuid path string true "圈子的UUID" format(uuid)
// // @Param        group body UpdateGroupInput true "要更新的圈子信息"
// // @Success      200  {object}  core.ApiResponse{data=models.Group} "圈子信息更新成功"
// // @Failure      400  {object}  core.ApiResponse "请求参数错误"
// // @Failure      403  {object}  core.ApiResponse "无权限操作"
// // @Security     BearerAuth
// // @Router       /groups/{uuid} [put]
// func (h *GroupHandler) UpdateGroup(c *gin.Context) {
// 	userID := c.MustGet("userID").(uint)
// 	groupUUID := c.Param("uuid")

// 	// 权限校验：必须是 owner 或 admin
// 	role, err := h.getUserRoleInGroup(groupUUID, userID)
// 	if err != nil {
// 		core.Error(c, "Group not found or permission denied")
// 		return
// 	}
// 	if role != models.RoleOwner && role != models.RoleAdmin {
// 		c.JSON(403, core.ApiResponse{Code: 1, Message: "Permission denied: must be an owner or admin"})
// 		return
// 	}

// 	var input UpdateGroupInput
// 	if err := c.ShouldBindJSON(&input); err != nil {
// 		core.Error(c, "Invalid input: "+err.Error())
// 		return
// 	}

// 	var group models.Group
// 	if err := h.DB.First(&group, "uuid = ?", groupUUID).Error; err != nil {
// 		core.Error(c, "Group not found")
// 		return
// 	}

// 	// 使用 Updates 进行部分更新
// 	if err := h.DB.Model(&group).Updates(models.Group{
// 		Name:        *input.Name,
// 		Description: *input.Description,
// 	}).Error; err != nil {
// 		core.Error(c, "Failed to update group")
// 		return
// 	}

// 	core.Success(c, "Group updated successfully", group)
// }

// // GetGroupMembers godoc
// // @Summary      获取圈子成员列表
// // @Description  获取指定圈子的所有成员及其角色
// // @Tags         Groups
// // @Produce      json
// // @Param        uuid path string true "圈子的UUID" format(uuid)
// // @Success      200  {object}  core.ApiResponse{data=[]GroupMemberResponse} "成功获取成员列表"
// // @Failure      400  {object}  core.ApiResponse "圈子未找到或无权限"
// // @Security     BearerAuth
// // @Router       /groups/{uuid}/members [get]
// func (h *GroupHandler) GetGroupMembers(c *gin.Context) {
// 	userID := c.MustGet("userID").(uint)
// 	groupUUID := c.Param("uuid")

// 	// 权限校验：确保用户是圈子成员
// 	if _, err := h.getUserRoleInGroup(groupUUID, userID); err != nil {
// 		core.Error(c, "Group not found or permission denied")
// 		return
// 	}

// 	var members []GroupMemberResponse
// 	err := h.DB.Table("group_members").
// 		Select("group_members.user_id, users.username, group_members.role, group_members.joined_at").
// 		Joins("JOIN users ON users.id = group_members.user_id").
// 		Joins("JOIN groups ON groups.id = group_members.group_id").
// 		Where("groups.uuid = ?", groupUUID).
// 		Order("group_members.joined_at asc").
// 		Scan(&members).Error

// 	if err != nil {
// 		core.Error(c, "Failed to fetch group members: "+err.Error())
// 		return
// 	}

// 	core.Success(c, "Group members retrieved successfully", members)
// }

// // --- Helper Functions ---

// // getUserRoleInGroup 是一个辅助函数，用于检查用户在特定圈子中的角色
// func (h *GroupHandler) getUserRoleInGroup(groupUUID string, userID uint) (models.GroupRole, error) {
// 	var member models.GroupMember
// 	err := h.DB.Joins("JOIN groups on groups.id = group_members.group_id").
// 		Where("groups.uuid = ? AND group_members.user_id = ?", groupUUID, userID).
// 		First(&member).Error

// 	if err != nil {
// 		return "", err // 如果找不到记录，gorm会返回 err
// 	}
// 	return member.Role, nil
// }

// // CreateInvite godoc
// // @Summary      创建邀请码
// // @Description  为指定的圈子创建一个有时效性的邀请码，仅限圈主或管理员操作。
// // @Tags         Groups
// // @Produce      json
// // @Param        uuid path string true "圈子的UUID" format(uuid)
// // @Success      200  {object}  core.ApiResponse{data=models.GroupInvite} "邀请码创建成功"
// // @Failure      400  {object}  core.ApiResponse "圈子未找到"
// // @Failure      403  {object}  core.ApiResponse "无权限操作"
// // @Security     BearerAuth
// // @Router       /groups/{uuid}/members/invite [post]
// func (h *GroupHandler) CreateInvite(c *gin.Context) {
// 	userID := c.MustGet("userID").(uint)
// 	groupUUID := c.Param("uuid")

// 	// 权限校验：必须是 owner 或 admin
// 	role, err := h.getUserRoleInGroup(groupUUID, userID)
// 	if err != nil {
// 		core.Error(c, "Group not found or permission denied")
// 		return
// 	}
// 	if role != models.RoleOwner && role != models.RoleAdmin {
// 		c.JSON(403, core.ApiResponse{Code: 1, Message: "Permission denied: must be an owner or admin"})
// 		return
// 	}

// 	var group models.Group
// 	if err := h.DB.First(&group, "uuid = ?", groupUUID).Error; err != nil {
// 		core.Error(c, "Group not found")
// 		return
// 	}

// 	// 创建邀请码
// 	invite := models.GroupInvite{
// 		GroupID:     group.ID,
// 		CreatedByID: userID,
// 		Code:        generateInviteCode(8),          // 生成一个8位的邀请码
// 		ExpiresAt:   time.Now().Add(48 * time.Hour), // 默认48小时后过期
// 		UsageLimit:  0,                              // 0表示无限制
// 	}

// 	if err := h.DB.Create(&invite).Error; err != nil {
// 		core.Error(c, "Failed to create invitation")
// 		return
// 	}

// 	core.Success(c, "Invitation created successfully", invite)
// }

// // JoinGroup godoc
// // @Summary      使用邀请码加入圈子
// // @Description  使用一个有效的邀请码加入对应的圈子
// // @Tags         Groups
// // @Accept       json
// // @Produce      json
// // @Param        input body JoinGroupInput true "邀请码"
// // @Success      200  {object}  core.ApiResponse{data=models.Group} "成功加入圈子"
// // @Failure      400  {object}  core.ApiResponse "邀请码无效、已过期或用户已是成员"
// // @Security     BearerAuth
// // @Router       /groups/join [post]
// func (h *GroupHandler) JoinGroup(c *gin.Context) {
// 	userID := c.MustGet("userID").(uint)

// 	var input JoinGroupInput
// 	if err := c.ShouldBindJSON(&input); err != nil {
// 		core.Error(c, "Invalid input: "+err.Error())
// 		return
// 	}

// 	var invite models.GroupInvite
// 	// 1. 校验邀请码是否存在
// 	if err := h.DB.Where("code = ?", input.Code).First(&invite).Error; err != nil {
// 		core.Error(c, "Invalid invitation code")
// 		return
// 	}

// 	// 2. 校验邀请码是否过期
// 	if time.Now().After(invite.ExpiresAt) {
// 		core.Error(c, "Invitation code has expired")
// 		return
// 	}

// 	// 3. 校验用户是否已经是该圈子成员
// 	var count int64
// 	h.DB.Model(&models.GroupMember{}).Where("group_id = ? AND user_id = ?", invite.GroupID, userID).Count(&count)
// 	if count > 0 {
// 		core.Error(c, "You are already a member of this group")
// 		return
// 	}

// 	// 4. 将用户加入圈子
// 	member := models.GroupMember{
// 		GroupID: invite.GroupID,
// 		UserID:  userID,
// 		Role:    models.RoleMember, // 默认角色为 'member'
// 	}

// 	if err := h.DB.Create(&member).Error; err != nil {
// 		core.Error(c, "Failed to join group: "+err.Error())
// 		return
// 	}

// 	// 成功加入后，返回该圈子的信息
// 	var group models.Group
// 	h.DB.First(&group, invite.GroupID)

// 	core.Success(c, "Successfully joined the group", group)
// }

// const inviteCodeCharset = "ABCDEFGHIJKLMNPQRSTUVWXYZ123456789" // 移除了 O 和 0 等易混淆字符

// var seededRand *rand.Rand = rand.New(rand.NewSource(time.Now().UnixNano()))

// // generateInviteCode 生成一个指定长度的随机字符串
// func generateInviteCode(length int) string {
// 	b := make([]byte, length)
// 	for i := range b {
// 		b[i] = inviteCodeCharset[seededRand.Intn(len(inviteCodeCharset))]
// 	}
// 	return string(b)
// }

// // ShareMediaToGroup godoc
// // @Summary      分享媒体到圈子
// // @Description  将当前用户拥有的一个或多个媒体分享到指定的圈子
// // @Tags         Groups
// // @Accept       json
// // @Produce      json
// // @Param        uuid path string true "圈子的UUID" format(uuid)
// // @Param        input body ShareMediaInput true "要分享的媒体UUID列表和可选的说明"
// // @Success      200  {object}  core.ApiResponse "媒体分享成功"
// // @Failure      400  {object}  core.ApiResponse "请求参数错误、照片未找到等"
// // @Failure      403  {object}  core.ApiResponse "无权限操作（非圈子成员）"
// // @Security     BearerAuth
// // @Router       /groups/{uuid}/media [post]
// func (h *GroupHandler) ShareMediaToGroup(c *gin.Context) {
// 	userID := c.MustGet("userID").(uint)
// 	groupUUID := c.Param("uuid")

// 	// 1. 权限校验：确保用户是圈子成员
// 	if _, err := h.getUserRoleInGroup(groupUUID, userID); err != nil {
// 		core.Error(c, "Group not found or you are not a member")
// 		return
// 	}

// 	var group models.Group
// 	if err := h.DB.First(&group, "uuid = ?", groupUUID).Error; err != nil {
// 		core.Error(c, "Group not found")
// 		return
// 	}

// 	var input ShareMediaInput
// 	if err := c.ShouldBindJSON(&input); err != nil {
// 		core.Error(c, "Invalid input: "+err.Error())
// 		return
// 	}
// 	if len(input.MediaUUIDs) == 0 {
// 		core.Error(c, "media_uuids cannot be empty")
// 		return
// 	}

// 	// 2. 关键安全校验：确保要分享的照片属于当前用户
// 	var userMedia []models.Media
// 	if err := h.DB.Where("uuid IN ? AND user_id = ?", input.MediaUUIDs, userID).Find(&userMedia).Error; err != nil {
// 		core.Error(c, "Failed to verify media ownership")
// 		return
// 	}

// 	// 检查是否有部分照片不属于该用户
// 	if len(userMedia) != len(input.MediaUUIDs) {
// 		core.Error(c, "Some media were not found or you do not have permission to share them")
// 		return
// 	}

// 	// 3. 构造 GroupMedia 记录并批量插入
// 	var groupMediaRecords []models.GroupMedia
// 	for _, media := range userMedia {
// 		groupMediaRecords = append(groupMediaRecords, models.GroupMedia{
// 			GroupID:    group.ID,
// 			MediaUUID:  media.UUID,
// 			UploaderID: userID,
// 			Caption:    input.Caption,
// 		})
// 	}

// 	if err := h.DB.Create(&groupMediaRecords).Error; err != nil {
// 		core.Error(c, "Failed to share media to the group")
// 		return
// 	}

// 	core.Success(c, "Media shared successfully", nil)
// }

// // GetGroupFeed godoc
// // @Summary      获取圈子 Feed 流
// // @Description  分页获取圈子中的媒体分享，按分享时间倒序排列
// // @Tags         Groups
// // @Produce      json
// // @Param        uuid path string true "圈子的UUID" format(uuid)
// // @Param        page query int false "页码" default(1)
// // @Param        limit query int false "每页数量" default(50)
// // @Success      200  {object}  core.ApiResponse{data=[]GroupFeedItemResponse} "成功获取Feed流"
// // @Failure      400  {object}  core.ApiResponse "请求参数错误"
// // @Failure      403  {object}  core.ApiResponse "无权限操作（非圈子成员）"
// // @Security     BearerAuth
// // @Router       /groups/{uuid}/media [get]
// func (h *GroupHandler) GetGroupFeed(c *gin.Context) {
// 	userID := c.MustGet("userID").(uint)
// 	groupUUID := c.Param("uuid")

// 	// 1. 权限校验：确保用户是圈子成员
// 	if _, err := h.getUserRoleInGroup(groupUUID, userID); err != nil {
// 		core.Error(c, "Group not found or you are not a member")
// 		return
// 	}

// 	// 2. 分页参数处理
// 	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
// 	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50")) // 默认每页50条
// 	if page < 1 {
// 		page = 1
// 	}
// 	offset := (page - 1) * limit

// 	// 3. 高性能查询
// 	// 直接查询 group_media 表，然后预加载关联数据
// 	var groupMediaList []models.GroupMedia
// 	err := h.DB.Joins("JOIN groups ON groups.id = group_media.group_id").
// 		Where("groups.uuid = ?", groupUUID).
// 		Order("group_media.created_at desc").
// 		Limit(limit).
// 		Offset(offset).
// 		// 使用 Preload 预加载上传者信息，避免 N+1 查询
// 		Preload("Uploader").
// 		Find(&groupMediaList).Error

// 	if err != nil {
// 		core.Error(c, "Failed to fetch group feed: "+err.Error())
// 		return
// 	}

// 	// 4. 构建最终响应
// 	// 为了获得完整的 Media 详情，我们需要单独查询一次
// 	mediaUUIDs := make([]string, len(groupMediaList))
// 	for i, gm := range groupMediaList {
// 		mediaUUIDs[i] = gm.MediaUUID
// 	}

// 	mediaDetailsMap := make(map[string]models.Media)
// 	if len(mediaUUIDs) > 0 {
// 		var mediaList []models.Media
// 		h.DB.Where("uuid IN ?", mediaUUIDs).Find(&mediaList)
// 		for _, m := range mediaList {
// 			mediaDetailsMap[m.UUID] = m
// 		}
// 	}

// 	// 组装成 GroupFeedItemResponse
// 	response := make([]GroupFeedItemResponse, len(groupMediaList))
// 	for i, gm := range groupMediaList {
// 		response[i] = GroupFeedItemResponse{
// 			GroupMediaID: gm.ID,
// 			Caption:      gm.Caption,
// 			SharedAt:     gm.CreatedAt,
// 			Uploader: UploaderInfo{
// 				UserID:   gm.Uploader.ID,
// 				Username: gm.Uploader.Username,
// 			},
// 			MediaDetails: mediaDetailsMap[gm.MediaUUID],
// 		}
// 	}

// 	core.Success(c, "Group feed retrieved successfully", response)
// }

// // --- 评论 (Comment) CRUD 接口 ---

// // AddComment godoc
// // @Summary      添加评论
// // @Description  为圈子中的某个媒体添加一条评论
// // @Tags         Groups
// // @Accept       json
// // @Produce      json
// // @Param        groupMediaId path int true "圈子媒体的ID (group_media_id)"
// // @Param        input body CreateCommentInput true "评论内容"
// // @Success      200  {object}  core.ApiResponse{data=models.Comment} "评论成功"
// // @Failure      400  {object}  core.ApiResponse "请求参数错误"
// // @Failure      403  {object}  core.ApiResponse "无权限操作（非圈子成员）"
// // @Security     BearerAuth
// // @Router       /group-media/{groupMediaId}/comments [post]
// func (h *GroupHandler) AddComment(c *gin.Context) {
// 	userID := c.MustGet("userID").(uint)
// 	groupMediaID, err := strconv.ParseUint(c.Param("groupMediaId"), 10, 64)
// 	if err != nil {
// 		core.Error(c, "Invalid group media ID")
// 		return
// 	}

// 	// 权限校验：确保用户是该媒体所在圈子的成员
// 	_, err = h.getGroupMediaAndCheckMembership(uint(groupMediaID), userID)
// 	if err != nil {
// 		core.Error(c, err.Error())
// 		return
// 	}

// 	var input CreateCommentInput
// 	if err := c.ShouldBindJSON(&input); err != nil {
// 		core.Error(c, "Invalid input: "+err.Error())
// 		return
// 	}

// 	comment := models.Comment{
// 		GroupMediaID: uint(groupMediaID),
// 		UserID:       userID,
// 		Content:      input.Content,
// 	}

// 	if err := h.DB.Create(&comment).Error; err != nil {
// 		core.Error(c, "Failed to add comment")
// 		return
// 	}

// 	core.Success(c, "Comment added successfully", comment)
// }

// // GetComments godoc
// // @Summary      获取评论列表
// // @Description  获取圈子中某个媒体的所有评论
// // @Tags         Groups
// // @Produce      json
// // @Param        groupMediaId path int true "圈子媒体的ID (group_media_id)"
// // @Success      200  {object}  core.ApiResponse{data=[]CommentResponse} "获取评论列表成功"
// // @Failure      400  {object}  core.ApiResponse "请求参数错误"
// // @Failure      403  {object}  core.ApiResponse "无权限操作（非圈子成员）"
// // @Security     BearerAuth
// // @Router       /group-media/{groupMediaId}/comments [get]
// func (h *GroupHandler) GetComments(c *gin.Context) {
// 	userID := c.MustGet("userID").(uint)
// 	groupMediaID, err := strconv.ParseUint(c.Param("groupMediaId"), 10, 64)
// 	if err != nil {
// 		core.Error(c, "Invalid group media ID")
// 		return
// 	}

// 	if _, err := h.getGroupMediaAndCheckMembership(uint(groupMediaID), userID); err != nil {
// 		core.Error(c, err.Error())
// 		return
// 	}

// 	var comments []models.Comment
// 	err = h.DB.Where("group_media_id = ?", groupMediaID).
// 		Preload("User"). // 预加载用户信息
// 		Order("created_at asc").
// 		Find(&comments).Error
// 	if err != nil {
// 		core.Error(c, "Failed to fetch comments")
// 		return
// 	}

// 	// 构建响应 DTO
// 	response := make([]CommentResponse, len(comments))
// 	for i, cm := range comments {
// 		response[i] = CommentResponse{
// 			ID:        cm.ID,
// 			CreatedAt: cm.CreatedAt,
// 			Content:   cm.Content,
// 			User: UserInfo{
// 				UserID:   cm.User.ID,
// 				Username: cm.User.Username,
// 			},
// 		}
// 	}

// 	core.Success(c, "Comments retrieved successfully", response)
// }

// // DeleteComment godoc
// // @Summary      删除评论
// // @Description  删除一条评论，仅限评论发布者或圈主/管理员操作
// // @Tags         Groups
// // @Produce      json
// // @Param        commentId path int true "评论的ID"
// // @Success      200  {object}  core.ApiResponse "评论删除成功"
// // @Failure      403  {object}  core.ApiResponse "无权限操作"
// // @Security     BearerAuth
// // @Router       /comments/{commentId} [delete]
// func (h *GroupHandler) DeleteComment(c *gin.Context) {
// 	userID := c.MustGet("userID").(uint)
// 	commentID, err := strconv.ParseUint(c.Param("commentId"), 10, 64)
// 	if err != nil {
// 		core.Error(c, "Invalid comment ID")
// 		return
// 	}

// 	var comment models.Comment
// 	if err := h.DB.First(&comment, uint(commentID)).Error; err != nil {
// 		core.Error(c, "Comment not found")
// 		return
// 	}

// 	groupMedia, err := h.getGroupMediaAndCheckMembership(comment.GroupMediaID, userID)
// 	if err != nil {
// 		core.Error(c, err.Error())
// 		return
// 	}

// 	group, _ := h.getGroupByID(groupMedia.GroupID)
// 	userRole, _ := h.getUserRoleInGroup(group.UUID, userID)

// 	// 权限校验：必须是评论发布者或圈主/管理员
// 	if comment.UserID != userID && userRole != models.RoleOwner && userRole != models.RoleAdmin {
// 		c.JSON(403, core.ApiResponse{Code: 1, Message: "You do not have permission to delete this comment"})
// 		return
// 	}

// 	if err := h.DB.Delete(&comment).Error; err != nil {
// 		core.Error(c, "Failed to delete comment")
// 		return
// 	}

// 	core.Success(c, "Comment deleted successfully", nil)
// }

// // --- 移除与退出机制 ---

// // RemoveMember godoc
// // @Summary      移除成员
// // @Description  从圈子中移除一个成员，仅限圈主或管理员操作
// // @Tags         Groups
// // @Produce      json
// // @Param        uuid path string true "圈子的UUID" format(uuid)
// // @Param        userId path int true "要移除的用户ID"
// // @Success      200  {object}  core.ApiResponse "成员移除成功"
// // @Failure      403  {object}  core.ApiResponse "无权限操作"
// // @Security     BearerAuth
// // @Router       /groups/{uuid}/members/{userId} [delete]
// func (h *GroupHandler) RemoveMember(c *gin.Context) {
// 	operatorID := c.MustGet("userID").(uint)
// 	groupUUID := c.Param("uuid")
// 	memberToRemoveID, err := strconv.ParseUint(c.Param("userId"), 10, 64)
// 	if err != nil {
// 		core.Error(c, "Invalid user ID")
// 		return
// 	}

// 	operatorRole, err := h.getUserRoleInGroup(groupUUID, operatorID)
// 	if err != nil || (operatorRole != models.RoleOwner && operatorRole != models.RoleAdmin) {
// 		c.JSON(403, core.ApiResponse{Code: 1, Message: "Permission denied: must be an owner or admin"})
// 		return
// 	}

// 	group, err := h.getGroupByUUID(groupUUID)
// 	if err != nil {
// 		core.Error(c, "Group not found")
// 		return
// 	}

// 	if group.OwnerID == uint(memberToRemoveID) {
// 		core.Error(c, "Cannot remove the group owner")
// 		return
// 	}

// 	// 删除成员关系
// 	result := h.DB.Where("group_id = ? AND user_id = ?", group.ID, memberToRemoveID).Delete(&models.GroupMember{})
// 	if result.Error != nil {
// 		core.Error(c, "Failed to remove member")
// 		return
// 	}
// 	if result.RowsAffected == 0 {
// 		core.Error(c, "Member not found in this group")
// 		return
// 	}

// 	core.Success(c, "Member removed successfully", nil)
// }

// // LeaveGroup godoc
// // @Summary      退出圈子
// // @Description  当前用户主动退出一个圈子，圈主无法退出
// // @Tags         Groups
// // @Produce      json
// // @Param        uuid path string true "圈子的UUID" format(uuid)
// // @Success      200  {object}  core.ApiResponse "成功退出圈子"
// // @Failure      400  {object}  core.ApiResponse "圈主无法退出"
// // @Security     BearerAuth
// // @Router       /groups/{uuid}/leave [post]
// func (h *GroupHandler) LeaveGroup(c *gin.Context) {
// 	userID := c.MustGet("userID").(uint)
// 	groupUUID := c.Param("uuid")

// 	group, err := h.getGroupByUUID(groupUUID)
// 	if err != nil {
// 		core.Error(c, "Group not found or you are not a member")
// 		return
// 	}

// 	if group.OwnerID == userID {
// 		core.Error(c, "Owner cannot leave the group. Please delete the group or transfer ownership first.")
// 		return
// 	}

// 	result := h.DB.Where("group_id = ? AND user_id = ?", group.ID, userID).Delete(&models.GroupMember{})
// 	if result.Error != nil || result.RowsAffected == 0 {
// 		core.Error(c, "Failed to leave group")
// 		return
// 	}

// 	core.Success(c, "Successfully left the group", nil)
// }

// // RemoveMediaFromGroup godoc
// // @Summary      从圈子移除照片
// // @Description  从圈子中移除一张照片，仅限照片上传者或圈主/管理员操作
// // @Tags         Groups
// // @Produce      json
// // @Param        groupMediaId path int true "圈子媒体的ID (group_media_id)"
// // @Success      200  {object}  core.ApiResponse "照片移除成功"
// // @Failure      403  {object}  core.ApiResponse "无权限操作"
// // @Security     BearerAuth
// // @Router       /group-media/{groupMediaId} [delete]
// func (h *GroupHandler) RemoveMediaFromGroup(c *gin.Context) {
// 	userID := c.MustGet("userID").(uint)
// 	groupMediaID, err := strconv.ParseUint(c.Param("groupMediaId"), 10, 64)
// 	if err != nil {
// 		core.Error(c, "Invalid group media ID")
// 		return
// 	}

// 	groupMedia, err := h.getGroupMediaAndCheckMembership(uint(groupMediaID), userID)
// 	if err != nil {
// 		core.Error(c, err.Error())
// 		return
// 	}

// 	group, _ := h.getGroupByID(groupMedia.GroupID)
// 	userRole, _ := h.getUserRoleInGroup(group.UUID, userID)

// 	// 权限校验：必须是上传者或圈主/管理员
// 	if groupMedia.UploaderID != userID && userRole != models.RoleOwner && userRole != models.RoleAdmin {
// 		c.JSON(403, core.ApiResponse{Code: 1, Message: "You do not have permission to remove this media"})
// 		return
// 	}

// 	if err := h.DB.Delete(&models.GroupMedia{}, groupMedia.ID).Error; err != nil {
// 		core.Error(c, "Failed to remove media from group")
// 		return
// 	}

// 	core.Success(c, "Media removed from group successfully", nil)
// }

// // getGroupMediaAndCheckMembership 检查用户是否有权访问某个 group_media
// func (h *GroupHandler) getGroupMediaAndCheckMembership(groupMediaID uint, userID uint) (*models.GroupMedia, error) {
// 	var groupMedia models.GroupMedia
// 	if err := h.DB.First(&groupMedia, groupMediaID).Error; err != nil {
// 		return nil, errors.New("media not found in any group")
// 	}

// 	var count int64
// 	h.DB.Model(&models.GroupMember{}).Where("group_id = ? AND user_id = ?", groupMedia.GroupID, userID).Count(&count)
// 	if count == 0 {
// 		return nil, errors.New("permission denied: you are not a member of the group containing this media")
// 	}

// 	return &groupMedia, nil
// }

// // getGroupByUUID 是一个辅助函数
// func (h *GroupHandler) getGroupByUUID(uuid string) (*models.Group, error) {
// 	var group models.Group
// 	err := h.DB.Where("uuid = ?", uuid).First(&group).Error
// 	return &group, err
// }

// // getGroupByID 是一个辅助函数
// func (h *GroupHandler) getGroupByID(id uint) (*models.Group, error) {
// 	var group models.Group
// 	err := h.DB.First(&group, id).Error
// 	return &group, err
// }
