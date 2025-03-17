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

// Bookmark 书签模型
type Bookmark struct {
	ID        primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	DeviceID  string             `bson:"deviceId" json:"deviceId"`
	NovelID   string             `bson:"novelId" json:"novelId"`
	VolumeID  int                `bson:"volumeId" json:"volumeId"`
	ChapterID int                `bson:"chapterId" json:"chapterId"`
	Position  int                `bson:"position" json:"position"`
	Note      string             `bson:"note" json:"note"`
	CreatedAt time.Time          `bson:"createdAt" json:"createdAt"`
	UpdatedAt time.Time          `bson:"updatedAt" json:"updatedAt"`
}

// ReadingProgress 阅读进度模型
type ReadingProgress struct {
	ID         primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	DeviceID   string             `bson:"deviceId" json:"deviceId"`
	NovelID    string             `bson:"novelId" json:"novelId"`
	VolumeID   int                `bson:"volumeId" json:"volumeId"`
	ChapterID  int                `bson:"chapterId" json:"chapterId"`
	Position   int                `bson:"position" json:"position"`
	LastReadAt time.Time          `bson:"lastReadAt" json:"lastReadAt"`
	CreatedAt  time.Time          `bson:"createdAt" json:"createdAt"`
	UpdatedAt  time.Time          `bson:"updatedAt" json:"updatedAt"`
}
