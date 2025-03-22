// ****************************************************************************
//
// @file       mongodb.go
// @brief      与MongoDB相关的数据库操作
//
// @author     KBchulan
// @date       2025/03/21
// @history
// ****************************************************************************

package database

import (
	"context"
	"fmt"
	"log"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type MongoDB struct {
	client   *mongo.Client
	database *mongo.Database
}

func NewMongoDB(uri, dbName string) (*MongoDB, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// 创建客户端
	client, err := mongo.Connect(ctx, options.Client().ApplyURI(uri))
	if err != nil {
		return nil, err
	}

	// 测试连接
	err = client.Ping(ctx, nil)
	if err != nil {
		return nil, err
	}

	log.Printf("Successfully connected to MongoDB: %s\n", uri)

	return &MongoDB{
		client:   client,
		database: client.Database(dbName),
	}, nil
}

func (m *MongoDB) Close() error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	return m.client.Disconnect(ctx)
}

func (m *MongoDB) GetCollection(name string) *mongo.Collection {
	return m.database.Collection(name)
}

func (m *MongoDB) GetDatabase() *mongo.Database {
	return m.database
}

// CreateIndexes 创建必要的数据库索引
func (db *MongoDB) CreateIndexes(ctx context.Context) error {
	// 小说集合索引
	novelIndexes := []mongo.IndexModel{
		{
			Keys: bson.D{
				{Key: "title", Value: "text"},
				{Key: "description", Value: "text"},
				{Key: "author", Value: "text"},
			},
			Options: options.Index().SetName("text_search"),
		},
		{
			Keys:    bson.D{{Key: "updatedAt", Value: -1}},
			Options: options.Index().SetName("updated_at"),
		},
		{
			Keys:    bson.D{{Key: "readCount", Value: -1}},
			Options: options.Index().SetName("read_count"),
		},
	}

	// 卷集合索引
	volumeIndexes := []mongo.IndexModel{
		{
			Keys: bson.D{
				{Key: "novelId", Value: 1},
				{Key: "volumeNumber", Value: 1},
			},
			Options: options.Index().SetName("novel_volume").SetUnique(true),
		},
	}

	// 章节集合索引
	chapterIndexes := []mongo.IndexModel{
		{
			Keys: bson.D{
				{Key: "novelId", Value: 1},
				{Key: "volumeNumber", Value: 1},
				{Key: "chapterNumber", Value: 1},
			},
			Options: options.Index().SetName("novel_chapter").SetUnique(true),
		},
	}

	// 设备集合索引
	deviceIndexes := []mongo.IndexModel{
		{
			Keys:    bson.D{{Key: "ip", Value: 1}},
			Options: options.Index().SetName("ip"),
		},
		{
			Keys:    bson.D{{Key: "lastSeen", Value: -1}},
			Options: options.Index().SetName("last_seen"),
		},
	}

	// 书签索引
	bookmarkIndexes := []mongo.IndexModel{
		{
			Keys: bson.D{
				{Key: "deviceId", Value: 1},
				{Key: "novelId", Value: 1},
			},
			Options: options.Index().SetName("device_novel_bookmark"),
		},
		{
			Keys:    bson.D{{Key: "createdAt", Value: -1}},
			Options: options.Index().SetName("created_at"),
		},
	}

	// 收藏索引
	favoriteIndexes := []mongo.IndexModel{
		{
			Keys: bson.D{
				{Key: "deviceId", Value: 1},
				{Key: "novelId", Value: 1},
			},
			Options: options.Index().SetName("device_novel_favorite").SetUnique(true),
		},
	}

	// 阅读历史索引
	readHistoryIndexes := []mongo.IndexModel{
		{
			Keys: bson.D{
				{Key: "deviceId", Value: 1},
				{Key: "novelId", Value: 1},
			},
			Options: options.Index().SetName("device_novel_history").SetUnique(true),
		},
		{
			Keys:    bson.D{{Key: "lastRead", Value: -1}},
			Options: options.Index().SetName("last_read"),
		},
	}

	// 阅读进度索引
	readProgressIndexes := []mongo.IndexModel{
		{
			Keys: bson.D{
				{Key: "deviceId", Value: 1},
				{Key: "novelId", Value: 1},
			},
			Options: options.Index().SetName("device_novel_progress").SetUnique(true),
		},
	}

	// 创建索引
	collections := map[string][]mongo.IndexModel{
		"novels":        novelIndexes,
		"volumes":       volumeIndexes,
		"chapters":      chapterIndexes,
		"devices":       deviceIndexes,
		"bookmarks":     bookmarkIndexes,
		"favorites":     favoriteIndexes,
		"read_history":  readHistoryIndexes,
		"read_progress": readProgressIndexes,
	}

	for collection, indexes := range collections {
		_, err := db.GetCollection(collection).Indexes().CreateMany(ctx, indexes)
		if err != nil {
			return fmt.Errorf("failed to create indexes for collection %s: %v", collection, err)
		}
	}

	return nil
}
