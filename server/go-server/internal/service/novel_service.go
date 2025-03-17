package service

import (
	"context"
	"fmt"
	"lightnovel/config"
	"lightnovel/internal/models"
	"lightnovel/pkg/cache"
	"lightnovel/pkg/database"
	"lightnovel/pkg/websocket"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// NovelService 小说服务
type NovelService struct {
	db    *database.MongoDB
	cache *cache.RedisCache
	wsHub *websocket.Hub
	cfg   *config.Config
}

// NewNovelService 创建小说服务
func NewNovelService(db *database.MongoDB, cache *cache.RedisCache, cfg *config.Config) *NovelService {
	return &NovelService{
		db:    db,
		cache: cache,
		wsHub: websocket.NewHub(),
		cfg:   cfg,
	}
}

// NotifyNovelUpdate 通知小说更新并清除相关缓存
func (s *NovelService) NotifyNovelUpdate(novelID string, title string) {
	ctx := context.Background()

	// 清除相关缓存
	s.cache.Delete(ctx, cache.NovelListKey)
	s.cache.Delete(ctx, cache.NovelDetailKey+novelID)
	s.cache.Delete(ctx, cache.LatestNovelsKey)
	s.cache.DeleteByPattern(ctx, cache.ChapterKey+novelID+"*")

	// 发送WebSocket通知
	message := fmt.Sprintf("小说《%s》已更新", title)
	s.wsHub.Broadcast <- []byte(message)
}

// GetAllNovels 获取所有小说（支持分页）
func (s *NovelService) GetAllNovels(ctx context.Context, page, size int) ([]models.Novel, int64, error) {
	var novels []models.Novel
	var total int64

	// 计算跳过的文档数
	skip := (page - 1) * size

	// 尝试从缓存获取
	cacheKey := fmt.Sprintf("%s:%d:%d", cache.NovelListKey, page, size)
	err := s.cache.Get(ctx, cacheKey, &novels)
	if err == nil && len(novels) > 0 {
		// 获取总数
		countKey := cache.NovelListKey + ":count"
		err = s.cache.Get(ctx, countKey, &total)
		if err == nil {
			return novels, total, nil
		}
	}

	// 从数据库获取
	collection := s.db.GetCollection("novels")

	// 获取总数
	total, err = collection.CountDocuments(ctx, bson.M{})
	if err != nil {
		return nil, 0, err
	}

	// 查询数据
	opts := options.Find().
		SetSort(bson.D{{Key: "updatedAt", Value: -1}}).
		SetSkip(int64(skip)).
		SetLimit(int64(size))

	cursor, err := collection.Find(ctx, bson.M{}, opts)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	if err = cursor.All(ctx, &novels); err != nil {
		return nil, 0, err
	}

	// 设置缓存
	s.cache.Set(ctx, cacheKey, novels, s.cfg.Cache.NovelList)
	s.cache.Set(ctx, cache.NovelListKey+":count", total, s.cfg.Cache.NovelList)

	return novels, total, nil
}

// GetNovelByID 根据ID获取小说
func (s *NovelService) GetNovelByID(ctx context.Context, id string) (*models.Novel, error) {
	var novel models.Novel
	cacheKey := cache.NovelDetailKey + id

	// 尝试从缓存获取
	err := s.cache.Get(ctx, cacheKey, &novel)
	if err == nil {
		return &novel, nil
	}

	// 从数据库获取
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, err
	}

	collection := s.db.GetCollection("novels")
	err = collection.FindOne(ctx, bson.M{"_id": objectID}).Decode(&novel)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, err
	}

	// 设置缓存，有效期30分钟
	s.cache.Set(ctx, cacheKey, novel, 30*time.Minute)
	return &novel, nil
}

// GetVolumesByNovelID 获取小说的所有卷
func (s *NovelService) GetVolumesByNovelID(ctx context.Context, novelID string) ([]models.Volume, error) {
	var volumes []models.Volume
	cacheKey := cache.VolumeListKey + novelID

	// 尝试从缓存获取
	err := s.cache.Get(ctx, cacheKey, &volumes)
	if err == nil && len(volumes) > 0 {
		return volumes, nil
	}

	// 从数据库获取
	collection := s.db.GetCollection("volumes")
	opts := options.Find().SetSort(bson.D{{Key: "volumeNumber", Value: 1}})

	cursor, err := collection.Find(ctx, bson.M{"novelId": novelID}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	if err = cursor.All(ctx, &volumes); err != nil {
		return nil, err
	}

	// 设置缓存
	s.cache.Set(ctx, cacheKey, volumes, s.cfg.Cache.VolumeList)
	return volumes, nil
}

// GetChaptersByVolumeID 获取卷的所有章节
func (s *NovelService) GetChaptersByVolumeID(ctx context.Context, novelID string, volumeNumber int) ([]models.Chapter, error) {
	var chapters []models.Chapter
	cacheKey := fmt.Sprintf("%s%s:%d", cache.ChapterListKey, novelID, volumeNumber)

	// 尝试从缓存获取
	err := s.cache.Get(ctx, cacheKey, &chapters)
	if err == nil && len(chapters) > 0 {
		return chapters, nil
	}

	// 从数据库获取
	collection := s.db.GetCollection("chapters")
	opts := options.Find().SetSort(bson.D{{Key: "chapterNumber", Value: 1}})

	cursor, err := collection.Find(ctx, bson.M{
		"novelId":      novelID,
		"volumeNumber": volumeNumber,
	}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	if err = cursor.All(ctx, &chapters); err != nil {
		return nil, err
	}

	// 设置缓存
	s.cache.Set(ctx, cacheKey, chapters, s.cfg.Cache.ChapterList)
	return chapters, nil
}

// GetChapterByNumber 获取指定章节
func (s *NovelService) GetChapterByNumber(ctx context.Context, novelID string, volumeNumber, chapterNumber int) (*models.Chapter, error) {
	var chapter models.Chapter
	cacheKey := fmt.Sprintf("%s%s:%d:%d", cache.ChapterKey, novelID, volumeNumber, chapterNumber)

	// 尝试从缓存获取
	err := s.cache.Get(ctx, cacheKey, &chapter)
	if err == nil {
		return &chapter, nil
	}

	// 从数据库获取
	collection := s.db.GetCollection("chapters")
	err = collection.FindOne(ctx, bson.M{
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

	// 设置缓存，有效期1小时
	s.cache.Set(ctx, cacheKey, chapter, time.Hour)
	return &chapter, nil
}

// SearchNovels 搜索小说
func (s *NovelService) SearchNovels(ctx context.Context, keyword string, page, size int) ([]models.Novel, int64, error) {
	var novels []models.Novel
	var total int64
	cacheKey := cache.SearchKey + keyword

	// 计算跳过的文档数
	skip := (page - 1) * size

	// 尝试从缓存获取
	err := s.cache.Get(ctx, cacheKey, &novels)
	if err == nil && len(novels) > 0 {
		// 获取总数
		countKey := cacheKey + ":count"
		err = s.cache.Get(ctx, countKey, &total)
		if err == nil {
			return novels, total, nil
		}
	}

	// 从数据库搜索
	filter := bson.M{
		"$or": []bson.M{
			{"title": bson.M{"$regex": keyword, "$options": "i"}},
			{"description": bson.M{"$regex": keyword, "$options": "i"}},
			{"author": bson.M{"$regex": keyword, "$options": "i"}},
			{"tags": bson.M{"$in": []string{keyword}}},
		},
	}

	// 获取总数
	total, err = s.db.GetCollection("novels").CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, err
	}

	// 查询数据
	opts := options.Find().
		SetSort(bson.D{{Key: "readCount", Value: -1}}).
		SetSkip(int64(skip)).
		SetLimit(int64(size))

	cursor, err := s.db.GetCollection("novels").Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	if err = cursor.All(ctx, &novels); err != nil {
		return nil, 0, err
	}

	// 设置缓存
	s.cache.Set(ctx, cacheKey, novels, s.cfg.Cache.SearchResult)
	s.cache.Set(ctx, cacheKey+":count", total, s.cfg.Cache.SearchResult)

	return novels, total, nil
}

// GetLatestNovels 获取最新小说
func (s *NovelService) GetLatestNovels(ctx context.Context, limit int) ([]models.Novel, error) {
	var novels []models.Novel

	// 尝试从缓存获取
	err := s.cache.Get(ctx, cache.LatestNovelsKey, &novels)
	if err == nil && len(novels) > 0 {
		return novels, nil
	}

	// 从数据库获取
	opts := options.Find().SetSort(bson.M{"updatedAt": -1}).SetLimit(int64(limit))
	cursor, err := s.db.GetCollection("novels").Find(ctx, bson.M{}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	if err = cursor.All(ctx, &novels); err != nil {
		return nil, err
	}

	// 设置缓存，有效期5分钟
	s.cache.Set(ctx, cache.LatestNovelsKey, novels, 5*time.Minute)
	return novels, nil
}

// GetPopularNovels 获取热门小说
func (s *NovelService) GetPopularNovels(ctx context.Context, limit int) ([]models.Novel, error) {
	var novels []models.Novel
	cacheKey := cache.PopularNovelsKey

	// 尝试从缓存获取
	err := s.cache.Get(ctx, cacheKey, &novels)
	if err == nil && len(novels) > 0 {
		return novels, nil
	}

	// 从数据库获取，基于阅读量排序
	opts := options.Find().
		SetSort(bson.D{
			{Key: "readCount", Value: -1},
			{Key: "updatedAt", Value: -1},
		}).
		SetLimit(int64(limit))

	cursor, err := s.db.GetCollection("novels").Find(ctx, bson.M{}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	if err = cursor.All(ctx, &novels); err != nil {
		return nil, err
	}

	// 设置缓存
	s.cache.Set(ctx, cacheKey, novels, s.cfg.Cache.PopularNovels)
	return novels, nil
}

// IncrementNovelReadCount 增加小说阅读量
func (s *NovelService) IncrementNovelReadCount(ctx context.Context, novelID string) error {
	objectID, err := primitive.ObjectIDFromHex(novelID)
	if err != nil {
		return err
	}

	_, err = s.db.GetCollection("novels").UpdateOne(
		ctx,
		bson.M{"_id": objectID},
		bson.M{"$inc": bson.M{"readCount": 1}},
	)
	if err != nil {
		return err
	}

	// 清除相关缓存
	s.cache.Delete(ctx, cache.PopularNovelsKey)
	s.cache.Delete(ctx, cache.NovelDetailKey+novelID)
	return nil
}

// GetUserBookmarks 获取用户书签
func (s *NovelService) GetUserBookmarks(ctx context.Context, deviceID string) ([]models.Bookmark, error) {
	var bookmarks []models.Bookmark
	cursor, err := s.db.GetCollection("bookmarks").Find(ctx, bson.M{"deviceId": deviceID})
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	if err = cursor.All(ctx, &bookmarks); err != nil {
		return nil, err
	}
	return bookmarks, nil
}

// UpdateReadingProgress 更新阅读进度
func (s *NovelService) UpdateReadingProgress(ctx context.Context, deviceID string, novelID string, volumeID int, chapterID int, position int) error {
	progress := models.ReadingProgress{
		DeviceID:   deviceID,
		NovelID:    novelID,
		VolumeID:   volumeID,
		ChapterID:  chapterID,
		Position:   position,
		LastReadAt: time.Now(),
		UpdatedAt:  time.Now(),
	}

	opts := options.Update().SetUpsert(true)
	filter := bson.M{
		"deviceId": deviceID,
		"novelId":  novelID,
	}
	update := bson.M{"$set": progress}

	_, err := s.db.GetCollection("reading_progress").UpdateOne(ctx, filter, update, opts)
	return err
}
