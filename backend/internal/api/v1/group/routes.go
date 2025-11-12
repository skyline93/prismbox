package group

import (
	"github.com/album/backend/internal/api/middleware"
	appctx "github.com/album/backend/internal/app"
	groupservice "github.com/album/backend/internal/service/group"
	"github.com/gin-gonic/gin"
)

// Service 别名，避免循环依赖
type Service = groupservice.Service

// RegisterRoutes 注册圈子相关路由
func RegisterRoutes(rg *gin.RouterGroup, app *appctx.App) {
	if app == nil || app.GroupService == nil {
		return
	}

	// 类型断言
	groupService, ok := app.GroupService.(Service)
	if !ok {
		return
	}

	handler := NewHandler(groupService)

	// 圈子相关路由
	groupRoutes := rg.Group("/groups")
	groupRoutes.Use(middleware.AuthMiddleware(app.AuthService))
	{
		groupRoutes.POST("", handler.CreateGroup)
		groupRoutes.GET("", handler.GetMyGroups)
		groupRoutes.POST("/join", handler.JoinGroup)
		groupRoutes.POST("/:uuid/leave", handler.LeaveGroup)
		groupRoutes.GET("/:uuid", handler.GetGroupDetails)
		groupRoutes.PUT("/:uuid", handler.UpdateGroup)
		groupRoutes.POST("/:uuid/posts", handler.CreatePost)
		groupRoutes.GET("/:uuid/feed", handler.GetGroupFeed)
		groupRoutes.GET("/:uuid/media/:media_uuid/thumbnail", handler.GetGroupMediaThumbnail)
		groupRoutes.GET("/:uuid/media/:media_uuid/preview", handler.GetGroupMediaPreview)
		groupRoutes.GET("/:uuid/members", handler.GetGroupMembers)
		groupRoutes.POST("/:uuid/members/invite", handler.CreateInvite)
		groupRoutes.DELETE("/:uuid/members/:userId", handler.RemoveMember)
	}

	// 帖子相关路由
	postRoutes := rg.Group("/posts")
	postRoutes.Use(middleware.AuthMiddleware(app.AuthService))
	{
		postRoutes.POST("/:postId/comments", handler.AddComment)
		postRoutes.GET("/:postId/comments", handler.GetComments)
	}

	// 评论相关路由
	commentRoutes := rg.Group("/comments")
	commentRoutes.Use(middleware.AuthMiddleware(app.AuthService))
	{
		commentRoutes.DELETE("/:commentId", handler.DeleteComment)
	}
}

