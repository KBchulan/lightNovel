package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Novel 小说模型
type Novel struct {
	ID          primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Title       string             `bson:"title" json:"title"`
	VolumeCount int                `bson:"volumeCount" json:"volumeCount"`
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
