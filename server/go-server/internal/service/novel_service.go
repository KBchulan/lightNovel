package service

import (
	"context"
	"lightnovel/internal/models"
	"lightnovel/pkg/database"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type NovelService struct {
	db *database.MongoDB
}

func NewNovelService(db *database.MongoDB) *NovelService {
	return &NovelService{db: db}
}

// GetAllNovels 获取所有小说
func (s *NovelService) GetAllNovels(ctx context.Context) ([]models.Novel, error) {
	collection := s.db.GetCollection("novels")

	// 设置排序：按更新时间倒序
	opts := options.Find().SetSort(bson.D{{Key: "updatedAt", Value: -1}})

	cursor, err := collection.Find(ctx, bson.M{}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var novels []models.Novel
	if err = cursor.All(ctx, &novels); err != nil {
		return nil, err
	}

	return novels, nil
}

// GetNovelByID 根据ID获取小说
func (s *NovelService) GetNovelByID(ctx context.Context, id string) (*models.Novel, error) {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, err
	}

	collection := s.db.GetCollection("novels")
	var novel models.Novel
	err = collection.FindOne(ctx, bson.M{"_id": objectID}).Decode(&novel)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, err
	}

	return &novel, nil
}

// GetVolumesByNovelID 获取小说的所有卷
func (s *NovelService) GetVolumesByNovelID(ctx context.Context, novelID string) ([]models.Volume, error) {
	collection := s.db.GetCollection("volumes")

	// 按卷号排序
	opts := options.Find().SetSort(bson.D{{Key: "volumeNumber", Value: 1}})

	cursor, err := collection.Find(ctx, bson.M{"novelId": novelID}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var volumes []models.Volume
	if err = cursor.All(ctx, &volumes); err != nil {
		return nil, err
	}

	return volumes, nil
}

// GetChaptersByVolumeID 获取卷的所有章节
func (s *NovelService) GetChaptersByVolumeID(ctx context.Context, novelID string, volumeNumber int) ([]models.Chapter, error) {
	collection := s.db.GetCollection("chapters")

	// 按章节号排序
	opts := options.Find().SetSort(bson.D{{Key: "chapterNumber", Value: 1}})

	cursor, err := collection.Find(ctx, bson.M{
		"novelId":      novelID,
		"volumeNumber": volumeNumber,
	}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var chapters []models.Chapter
	if err = cursor.All(ctx, &chapters); err != nil {
		return nil, err
	}

	return chapters, nil
}

// GetChapterByNumber 获取指定章节
func (s *NovelService) GetChapterByNumber(ctx context.Context, novelID string, volumeNumber, chapterNumber int) (*models.Chapter, error) {
	collection := s.db.GetCollection("chapters")
	var chapter models.Chapter
	err := collection.FindOne(ctx, bson.M{
		"novelId":       novelID,
		"volumeNumber":  volumeNumber,
		"chapterNumber": chapterNumber,
	}).Decode(&chapter)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, err
	}

	return &chapter, nil
}
