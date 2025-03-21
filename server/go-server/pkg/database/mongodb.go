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
			Keys:    bson.D{{Key: "tags", Value: 1}},
			Options: options.Index().SetName("tags"),
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
			Keys:    bson.D{{Key: "lastSeen", Value: -1}},
			Options: options.Index().SetName("last_seen"),
		},
		{
			Keys:    bson.D{{Key: "ip", Value: 1}},
			Options: options.Index().SetName("ip"),
		},
	}

	// 阅读进度索引
	progressIndexes := []mongo.IndexModel{
		{
			Keys: bson.D{
				{Key: "deviceId", Value: 1},
				{Key: "novelId", Value: 1},
			},
			Options: options.Index().SetName("device_novel").SetUnique(true),
		},
		{
			Keys:    bson.D{{Key: "currentProgress.lastReadAt", Value: -1}},
			Options: options.Index().SetName("last_read"),
		},
	}

	// 书签索引
	bookmarkIndexes := []mongo.IndexModel{
		{
			Keys: bson.D{
				{Key: "deviceId", Value: 1},
				{Key: "novelId", Value: 1},
				{Key: "createdAt", Value: -1},
			},
			Options: options.Index().SetName("device_novel_time"),
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
		{
			Keys:    bson.D{{Key: "createdAt", Value: -1}},
			Options: options.Index().SetName("favorite_time"),
		},
	}

	// 创建索引
	collections := map[string][]mongo.IndexModel{
		"novels":           novelIndexes,
		"volumes":          volumeIndexes,
		"chapters":         chapterIndexes,
		"devices":          deviceIndexes,
		"reading_progress": progressIndexes,
		"bookmarks":        bookmarkIndexes,
		"favorites":        favoriteIndexes,
		"read_records": {
			{
				Keys: bson.D{
					{Key: "deviceId", Value: 1},
					{Key: "novelId", Value: 1},
					{Key: "readAt", Value: -1},
				},
				Options: options.Index().SetName("device_novel_time"),
			},
			{
				Keys:    bson.D{{Key: "readAt", Value: -1}},
				Options: options.Index().SetName("read_time"),
			},
			{
				Keys:    bson.D{{Key: "readDuration", Value: -1}},
				Options: options.Index().SetName("read_duration"),
			},
			{
				Keys:    bson.D{{Key: "isComplete", Value: 1}},
				Options: options.Index().SetName("complete_status"),
			},
			{
				Keys:    bson.D{{Key: "source", Value: 1}},
				Options: options.Index().SetName("read_source"),
			},
		},
		"read_chapters": {
			{
				Keys: bson.D{
					{Key: "deviceId", Value: 1},
					{Key: "novelId", Value: 1},
					{Key: "volumeNumber", Value: 1},
					{Key: "chapterNumber", Value: 1},
				},
				Options: options.Index().SetName("device_novel_chapter").SetUnique(true),
			},
			{
				Keys:    bson.D{{Key: "lastReadAt", Value: -1}},
				Options: options.Index().SetName("last_read_time"),
			},
			{
				Keys:    bson.D{{Key: "readCount", Value: -1}},
				Options: options.Index().SetName("read_count"),
			},
			{
				Keys:    bson.D{{Key: "isComplete", Value: 1}},
				Options: options.Index().SetName("chapter_complete"),
			},
			{
				Keys:    bson.D{{Key: "lastPosition", Value: 1}},
				Options: options.Index().SetName("last_position"),
			},
		},
		"reading_stats": {
			{
				Keys: bson.D{
					{Key: "deviceId", Value: 1},
					{Key: "novelId", Value: 1},
				},
				Options: options.Index().SetName("device_novel_stats").SetUnique(true),
			},
			{
				Keys:    bson.D{{Key: "lastActiveDate", Value: -1}},
				Options: options.Index().SetName("last_active"),
			},
			{
				Keys:    bson.D{{Key: "totalReadTime", Value: -1}},
				Options: options.Index().SetName("total_read_time"),
			},
			{
				Keys:    bson.D{{Key: "chapterRead", Value: -1}},
				Options: options.Index().SetName("chapter_read"),
			},
			{
				Keys:    bson.D{{Key: "completeCount", Value: -1}},
				Options: options.Index().SetName("complete_count"),
			},
			{
				Keys:    bson.D{{Key: "readProgress", Value: -1}},
				Options: options.Index().SetName("read_progress"),
			},
		},
	}

	for collection, indexes := range collections {
		_, err := db.GetCollection(collection).Indexes().CreateMany(ctx, indexes)
		if err != nil {
			return fmt.Errorf("failed to create indexes for collection %s: %v", collection, err)
		}
	}

	return nil
}
