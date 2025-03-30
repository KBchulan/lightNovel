// ****************************************************************************
//
// @file       novel.go
// @brief      所有模型
//
// @author     KBchulan
// @date       2025/03/21
// @history
// ****************************************************************************

package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Novel 小说模型
type Novel struct {
	ID          primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Title       string             `bson:"title" json:"title"`
	Author      string             `bson:"author" json:"author"`
	Description string             `bson:"description" json:"description"`
	Cover       string             `bson:"cover" json:"cover"`
	VolumeCount int                `bson:"volumeCount" json:"volumeCount"`
	Tags        []string           `bson:"tags" json:"tags"`
	Status      string             `bson:"status" json:"status"`
	ReadCount   int64              `bson:"readCount" json:"readCount"`
	CreatedAt   time.Time          `bson:"createdAt" json:"createdAt"`
	UpdatedAt   time.Time          `bson:"updatedAt" json:"updatedAt"`
}

// Volume 卷模型
type Volume struct {
	ID           primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	NovelID      primitive.ObjectID `bson:"novelId" json:"novelId"`
	VolumeNumber int                `bson:"volumeNumber" json:"volumeNumber"`
	ChapterCount int                `bson:"chapterCount" json:"chapterCount"`
	CreatedAt    time.Time          `bson:"createdAt" json:"createdAt"`
	UpdatedAt    time.Time          `bson:"updatedAt" json:"updatedAt"`
}

// Chapter 章节模型
type Chapter struct {
	ID            primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	NovelID       primitive.ObjectID `bson:"novelId" json:"novelId"`
	VolumeNumber  int                `bson:"volumeNumber" json:"volumeNumber"`
	ChapterNumber int                `bson:"chapterNumber" json:"chapterNumber"`
	Title         string             `bson:"title" json:"title"`
	Content       string             `bson:"content" json:"content"`
	HasImages     bool               `bson:"hasImages" json:"hasImages"`
	ImagePath     string             `bson:"imagePath,omitempty" json:"imagePath,omitempty"`
	ImageCount    int                `bson:"imageCount" json:"imageCount"`
	CreatedAt     time.Time          `bson:"createdAt" json:"createdAt"`
	UpdatedAt     time.Time          `bson:"updatedAt" json:"updatedAt"`
}

// ChapterInfo 章节基本信息
type ChapterInfo struct {
	ID            primitive.ObjectID `json:"id"`
	NovelID       primitive.ObjectID `json:"novelId"`
	VolumeNumber  int                `json:"volumeNumber"`
	ChapterNumber int                `json:"chapterNumber"`
	Title         string             `json:"title"`
	CreatedAt     time.Time          `json:"createdAt"`
	UpdatedAt     time.Time          `json:"updatedAt"`
}

// Device 设备信息模型
type Device struct {
	ID         string    `bson:"_id" json:"id"` // UUID作为设备唯一标识
	IP         string    `bson:"ip" json:"ip"`  // 最后使用的IP
	UserAgent  string    `bson:"userAgent" json:"userAgent"`
	DeviceType string    `bson:"deviceType" json:"deviceType"` // mobile/pc/tablet
	FirstSeen  time.Time `bson:"firstSeen" json:"firstSeen"`
	LastSeen   time.Time `bson:"lastSeen" json:"lastSeen"`
}

// Bookmark 书签模型
type Bookmark struct {
	ID            primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	DeviceID      string             `bson:"deviceId" json:"deviceId"`
	NovelID       string             `bson:"novelId" json:"novelId"`
	VolumeNumber  int                `bson:"volumeNumber" json:"volumeNumber"`
	ChapterNumber int                `bson:"chapterNumber" json:"chapterNumber"`
	Position      int                `bson:"position" json:"position"`
	Note          string             `bson:"note" json:"note"`
	CreatedAt     time.Time          `bson:"createdAt" json:"createdAt"`
	UpdatedAt     time.Time          `bson:"updatedAt" json:"updatedAt"`
}

// Favorite 收藏模型
type Favorite struct {
	ID        primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	DeviceID  string             `bson:"deviceId" json:"deviceId"`
	NovelID   string             `bson:"novelId" json:"novelId"`
	CreatedAt time.Time          `bson:"createdAt" json:"createdAt"`
	UpdatedAt time.Time          `bson:"updatedAt" json:"updatedAt"`
}

// ReadHistory 阅读历史
type ReadHistory struct {
	ID       primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	DeviceID string             `bson:"deviceId" json:"deviceId"`
	NovelID  string             `bson:"novelId" json:"novelId"`
	LastRead time.Time          `bson:"lastRead" json:"lastRead"` // 最后阅读时间,用于排序
}

// ReadProgress 阅读进度
type ReadProgress struct {
	ID            primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	DeviceID      string             `bson:"deviceId" json:"deviceId"`
	NovelID       string             `bson:"novelId" json:"novelId"`
	VolumeNumber  int                `bson:"volumeNumber" json:"volumeNumber"`
	ChapterNumber int                `bson:"chapterNumber" json:"chapterNumber"`
	Position      int                `bson:"position" json:"position"`
	UpdatedAt     time.Time          `bson:"updatedAt" json:"updatedAt"`
}

// User 用户模型
type User struct {
	ID           string    `bson:"_id" json:"id"`
	Name         string    `bson:"name" json:"name"`
	Avatar       string    `bson:"avatar" json:"avatar"`
	CreatedAt    time.Time `bson:"createdAt" json:"createdAt"`
	UpdatedAt    time.Time `bson:"updatedAt" json:"updatedAt"`
	LastActiveAt time.Time `bson:"lastActiveAt" json:"lastActiveAt"`
}

// Comment 评论模型
type Comment struct {
	ID            primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	DeviceID      string             `bson:"deviceId" json:"deviceId"`
	NovelID       string             `bson:"novelId" json:"novelId"`
	VolumeNumber  int                `bson:"volumeNumber" json:"volumeNumber"`
	ChapterNumber int                `bson:"chapterNumber" json:"chapterNumber"`
	Content       string             `bson:"content" json:"content"`
	CreatedAt     time.Time          `bson:"createdAt" json:"createdAt"`
	UpdatedAt     time.Time          `bson:"updatedAt" json:"updatedAt"`
}

// CommentResponse 评论响应类型(包含用户信息)
type CommentResponse struct {
	ID            primitive.ObjectID `json:"id"`
	UserID        string             `json:"userId"`
	UserName      string             `json:"userName"`
	UserAvatar    string             `json:"userAvatar"`
	NovelID       string             `json:"novelId"`
	VolumeNumber  int                `json:"volumeNumber"`
	ChapterNumber int                `json:"chapterNumber"`
	Content       string             `json:"content"`
	CreatedAt     time.Time          `json:"createdAt"`
}
