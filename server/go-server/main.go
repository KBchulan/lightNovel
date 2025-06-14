// ****************************************************************************
//
// @file       main.go
// @brief      主函数,梦开始的地方
//
// @author     KBchulan
// @date       2025/03/21
// @history
// ****************************************************************************

package main

import (
	"context"
	"fmt"
	v1 "lightnovel/api/v1"
	"lightnovel/config"
	_ "lightnovel/docs" // 导入 swagger 文档
	"lightnovel/internal/service"
	"lightnovel/pkg/cache"
	"lightnovel/pkg/database"
	"lightnovel/pkg/middleware"
	"log"
	"time"

	"github.com/gin-gonic/gin"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
	"golang.org/x/time/rate"
)

// @title Light Novel API
// @version 1.0
// @description 轻小说阅读API服务
// @BasePath /api/v1

func main() {
	// 设置为发布模式
	gin.SetMode(gin.ReleaseMode)

	// 加载配置
	cfg := config.LoadConfig()

	// 连接数据库
	db, err := database.NewMongoDB(cfg.Database.URI, cfg.Database.Database)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// 创建数据库索引
	ctx := context.Background()
	if err := db.CreateIndexes(ctx); err != nil {
		log.Printf("Warning: Failed to create indexes: %v", err)
	}

	// 创建Redis缓存
	redisAddr := fmt.Sprintf("%s:%s", cfg.Redis.Host, cfg.Redis.Port)
	multiLevelCache, err := cache.NewMultiLevelCache(redisAddr, cfg.Redis.Password, cfg.Redis.DB, "lightnovel:")
	if err != nil {
		log.Fatalf("Failed to create cache: %v", err)
	}
	defer multiLevelCache.Close()

	// 创建服务和处理器
	novelService := service.NewNovelService(db, multiLevelCache, cfg)
	novelHandler := v1.NewNovelHandler(novelService)
	healthHandler := v1.NewHealthHandler()
	wsHandler := v1.NewWebSocketHandler(cfg)

	// 创建路由
	r := gin.New()

	// 使用中间件
	r.Use(gin.Recovery())
	r.Use(middleware.Logger())
	r.Use(middleware.SecurityHeaders())
	r.Use(middleware.CORS())
	r.Use(middleware.DeviceMiddleware(novelService))

	// 创建限流器
	rateLimiter := middleware.NewRateLimiter(
		rate.Limit(cfg.Rate.Limit),
		cfg.Rate.Burst,
		middleware.WithRedis(multiLevelCache.GetRedisClient(), "ratelimit:"),
		middleware.WithCleanup(5*time.Minute),
	)
	r.Use(rateLimiter.RateLimit())

	// 静态文件服务
	r.Static("/novels", "../novels")
	r.Static("/static/avatars", "./static/avatars")

	// API文档
	r.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	// API路由
	api := r.Group("/api/v1")
	{
		// WebSocket连接
		api.GET("/ws", wsHandler.HandleConnection)
		api.GET("/ws/status", wsHandler.GetStatus)

		// 健康检查
		api.GET("/health", healthHandler.Check)
		api.GET("/metrics", healthHandler.Metrics)

		// 小说相关路由组
		novels := api.Group("/novels")
		{
			// 分页路由
			novels.GET("", middleware.ValidatePagination(), novelHandler.GetAllNovels)
			novels.GET("/search", middleware.ValidatePagination(), novelHandler.SearchNovels)

			// 限制数量的路由
			novels.GET("/latest", middleware.ValidateLimit(1000, 1000), novelHandler.GetLatestNovels)
			novels.GET("/popular", middleware.ValidateLimit(1000, 1000), novelHandler.GetPopularNovels)

			// 基于ID的路由
			novels.GET("/:id", novelHandler.GetNovelByID)
			novels.GET("/:id/volumes", novelHandler.GetVolumesByNovelID)
			novels.GET("/:id/volumes/:volume/chapters", novelHandler.GetChaptersByVolumeID)
			novels.GET("/:id/volumes/:volume/chapters/:chapter", novelHandler.GetChapterByNumber)

			// 章节评论路由
			novels.GET("/:id/volumes/:volume/chapters/:chapter/comments", novelHandler.GetComments)
			novels.POST("/:id/volumes/:volume/chapters/:chapter/comments", novelHandler.CreateComment)
		}

		// 用户相关路由组
		user := api.Group("/user")
		{
			// 收藏相关
			user.GET("/favorites", novelHandler.GetUserFavorites)
			user.POST("/favorites/:novel_id", novelHandler.AddFavorite)
			user.DELETE("/favorites/:novel_id", novelHandler.RemoveFavorite)
			user.GET("/favorites/:novel_id/check", novelHandler.IsFavorite)

			// 书签相关
			user.GET("/bookmarks", novelHandler.GetUserBookmarks)
			user.POST("/bookmarks", novelHandler.CreateBookmark)
			user.DELETE("/bookmarks/:id", novelHandler.DeleteBookmark)
			user.PUT("/bookmarks/:id", novelHandler.UpdateBookmark)

			// 阅读相关路由组
			reading := user.Group("/reading")
			{
				// 阅读历史
				reading.GET("/history", novelHandler.GetReadHistory)
				reading.PUT("/history/:novel_id", novelHandler.UpsertReadHistory)
				reading.DELETE("/history/:novel_id", novelHandler.DeleteReadHistory)
				reading.DELETE("/history", novelHandler.ClearReadHistory)

				// 阅读进度
				reading.GET("/progress/:novel_id", novelHandler.GetReadProgress)
				reading.PUT("/progress/:novel_id", novelHandler.UpdateReadProgress)
				reading.DELETE("/progress/:novel_id", novelHandler.DeleteReadProgress)
			}

			// 用户资料路由
			user.GET("/profile", novelHandler.GetUserProfile)
			user.PUT("/profile", novelHandler.UpdateUserProfile)

			user.POST("/upload/avatar", novelHandler.UploadAvatar)
		}

		// 评论相关路由
		comments := api.Group("/comments")
		{
			comments.DELETE("/:comment_id", novelHandler.DeleteComment)
		}
	}

	// 启动服务器
	addr := fmt.Sprintf(":%s", cfg.Server.Port)
	log.Printf("Server starting on %s", addr)
	if err := r.Run(addr); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
