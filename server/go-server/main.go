package main

import (
	"fmt"
	v1 "lightnovel/api/v1"
	"lightnovel/config"
	"lightnovel/internal/service"
	"lightnovel/pkg/database"
	"log"

	"github.com/gin-gonic/gin"
)

func main() {
	// 加载配置
	cfg := config.LoadConfig()

	// 连接数据库
	db, err := database.NewMongoDB(cfg.Database.URI, cfg.Database.Database)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// 创建服务和处理器
	novelService := service.NewNovelService(db)
	novelHandler := v1.NewNovelHandler(novelService)

	// 创建路由
	r := gin.Default()

	// API 路由组 v1
	v1Group := r.Group("/api/v1")
	{
		// 小说相关路由
		novels := v1Group.Group("/novels")
		{
			novels.GET("", novelHandler.GetAllNovels)
			novels.GET("/:id", novelHandler.GetNovelByID)
			novels.GET("/:id/volumes", novelHandler.GetVolumesByNovelID)
			novels.GET("/:id/volumes/:volume/chapters", novelHandler.GetChaptersByVolumeID)
			novels.GET("/:id/volumes/:volume/chapters/:chapter", novelHandler.GetChapterByNumber)
		}
	}

	// 启动服务器
	addr := fmt.Sprintf(":%s", cfg.Server.Port)
	log.Printf("Server starting on %s", addr)
	if err := r.Run(addr); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
