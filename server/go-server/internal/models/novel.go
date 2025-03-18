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
	Status      string             `bson:"status" json:"status"`       // 连载中、已完结
	ReadCount   int64              `bson:"readCount" json:"readCount"` // 阅读量
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

// ChapterInfo 章节基本信息（不包含内容）
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

// CurrentProgress 当前阅读进度
type CurrentProgress struct {
	VolumeNumber  int       `bson:"volumeNumber" json:"volumeNumber"`
	ChapterNumber int       `bson:"chapterNumber" json:"chapterNumber"`
	Position      int       `bson:"position" json:"position"`
	LastReadAt    time.Time `bson:"lastReadAt" json:"lastReadAt"`
}

// ReadingProgress 阅读进度模型
type ReadingProgress struct {
	ID              primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	DeviceID        string             `bson:"deviceId" json:"deviceId"`
	NovelID         string             `bson:"novelId" json:"novelId"`
	CurrentProgress CurrentProgress    `bson:"currentProgress" json:"currentProgress"`
	CreatedAt       time.Time          `bson:"createdAt" json:"createdAt"`
	UpdatedAt       time.Time          `bson:"updatedAt" json:"updatedAt"`
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
