// ****************************************************************************
//
// @file       novel_service.go
// @brief      直接与数据库和Redis交互的逻辑
//
// @author     KBchulan
// @date       2025/03/21
// @history
// ****************************************************************************

package service

import (
	"context"
	"fmt"
	"log"
	"strings"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"lightnovel/config"
	"lightnovel/internal/models"
	"lightnovel/pkg/cache"
	"lightnovel/pkg/concurrency"
	"lightnovel/pkg/database"
	"lightnovel/pkg/errors"
	"lightnovel/pkg/websocket"

	"github.com/google/uuid"
)

// NovelService 小说服务
type NovelService struct {
	db    *database.MongoDB
	cache cache.Cache
	wsHub *websocket.Hub
	cfg   *config.Config
}

// NewNovelService 创建小说服务
func NewNovelService(db *database.MongoDB, cache cache.Cache, cfg *config.Config) *NovelService {
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
	if err == nil && !novel.ID.IsZero() {
		return &novel, nil
	}

	// 从数据库获取
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, errors.NewError(errors.ErrInvalidParameter)
	}

	collection := s.db.GetCollection("novels")
	err = collection.FindOne(ctx, bson.M{"_id": objectID}).Decode(&novel)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, errors.NewError(errors.ErrNotFound)
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

// ExtractChapterTitle 从章节内容中提取标题
func ExtractChapterTitle(content string) string {
	// 如果内容为空，返回空标题
	if content == "" {
		return ""
	}

	// 按行分割内容
	lines := strings.Split(content, "\n")

	// 跳过可能的元数据（如图源、录入者等信息）
	startIndex := 0
	for i, line := range lines {
		if strings.Contains(line, "录入") || strings.Contains(line, "图源") {
			startIndex = i + 1
			continue
		}
		// 找到第一个非空且不是元数据的行
		if i > startIndex && line != "" && !strings.Contains(line, "转自") {
			// 如果这行文本长度合适，就把它当作标题
			if len(line) <= 50 {
				return line
			}
			// 如果这行太长，就取前30个字符加省略号
			return line[:30] + "..."
		}
	}

	return "第1话" // 默认标题
}

// UpdateChapterTitle 更新章节标题
func (s *NovelService) UpdateChapterTitle(ctx context.Context, chapter *models.Chapter) error {
	if chapter.Title != "" {
		return nil // 如果已有标题，不需要更新
	}

	// 从内容中提取标题
	title := ExtractChapterTitle(chapter.Content)
	if title == "" {
		title = fmt.Sprintf("第%d话", chapter.ChapterNumber)
	}

	// 更新数据库
	_, err := s.db.GetCollection("chapters").UpdateOne(
		ctx,
		bson.M{"_id": chapter.ID},
		bson.M{"$set": bson.M{"title": title}},
	)
	if err != nil {
		return err
	}

	// 更新内存中的章节对象
	chapter.Title = title

	// 清除相关缓存
	cacheKey := fmt.Sprintf("%s%s:%d", cache.ChapterListKey, chapter.NovelID, chapter.VolumeNumber)
	s.cache.Delete(ctx, cacheKey)

	return nil
}

// GetChaptersByVolumeID 获取卷的所有章节
func (s *NovelService) GetChaptersByVolumeID(ctx context.Context, novelID string, volumeNumber int) ([]models.ChapterInfo, error) {
	var chapters []models.Chapter
	var chapterInfos []models.ChapterInfo
	cacheKey := fmt.Sprintf("%s%s:%d", cache.ChapterListKey, novelID, volumeNumber)

	// 尝试从缓存获取
	err := s.cache.Get(ctx, cacheKey, &chapterInfos)
	if err == nil && len(chapterInfos) > 0 {
		return chapterInfos, nil
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

	// 转换为章节基本信息，同时检查并更新标题
	chapterInfos = make([]models.ChapterInfo, len(chapters))
	for i, ch := range chapters {
		// 如果没有标题，尝试更新
		if ch.Title == "" {
			if err := s.UpdateChapterTitle(ctx, &ch); err != nil {
				// 如果更新失败，使用默认标题
				ch.Title = fmt.Sprintf("第%d话", ch.ChapterNumber)
			}
		}

		chapterInfos[i] = models.ChapterInfo{
			ID:            ch.ID,
			NovelID:       ch.NovelID,
			VolumeNumber:  ch.VolumeNumber,
			ChapterNumber: ch.ChapterNumber,
			Title:         ch.Title,
			CreatedAt:     ch.CreatedAt,
			UpdatedAt:     ch.UpdatedAt,
		}
	}

	// 设置缓存
	s.cache.Set(ctx, cacheKey, chapterInfos, s.cfg.Cache.ChapterList)
	return chapterInfos, nil
}

// GetChapterByNumber 获取指定章节
func (s *NovelService) GetChapterByNumber(ctx context.Context, novelID string, volumeNumber, chapterNumber int) (*models.Chapter, error) {
	var chapter models.Chapter
	cacheKey := fmt.Sprintf("%s%s:%d:%d", cache.ChapterKey, novelID, volumeNumber, chapterNumber)

	// 尝试从缓存获取
	err := s.cache.Get(ctx, cacheKey, &chapter)
	if err == nil && !chapter.ID.IsZero() {
		return &chapter, nil
	}

	// 从数据库获取
	collection := s.db.GetCollection("chapters")
	filter := bson.M{
		"novelId":       novelID,
		"volumeNumber":  volumeNumber,
		"chapterNumber": chapterNumber,
	}

	err = collection.FindOne(ctx, filter).Decode(&chapter)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, errors.NewError(errors.ErrNotFound)
		}
		return nil, err
	}

	// 如果章节没有标题，尝试从内容中提取
	if chapter.Title == "" {
		if err := s.UpdateChapterTitle(ctx, &chapter); err != nil {
			// 如果更新失败，使用默认标题
			chapter.Title = fmt.Sprintf("第%d话", chapter.ChapterNumber)
		}
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

// NovelTask 表示获取小说的任务
type NovelTask struct {
	service *NovelService
	novelID string
}

// Execute 执行获取小说任务
func (t *NovelTask) Execute(ctx context.Context) error {
	novel, err := t.service.GetNovelByID(ctx, t.novelID)
	if err != nil {
		return err
	}

	// 更新缓存
	err = t.service.cache.Set(ctx, fmt.Sprintf("novel:%s", t.novelID), novel, 30*time.Minute)
	return err
}

// GetPopularNovelsParallel 并行获取热门小说
func (s *NovelService) GetPopularNovelsParallel(ctx context.Context, limit int) ([]*models.Novel, error) {
	// 使用16线程的工作池（对应您的CPU核心数）
	pool := concurrency.NewWorkerPool(16)
	pool.Start(ctx)
	defer pool.Stop()

	// 尝试从缓存获取
	cacheKey := fmt.Sprintf("popular_novels:%d", limit)
	var cachedNovels []*models.Novel
	if err := s.cache.Get(ctx, cacheKey, &cachedNovels); err == nil && len(cachedNovels) > 0 {
		return cachedNovels, nil
	}

	// 从数据库获取热门小说
	opts := options.Find().
		SetSort(bson.D{{Key: "readCount", Value: -1}}).
		SetLimit(int64(limit))

	cursor, err := s.db.GetCollection("novels").Find(ctx, bson.M{}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var novels []*models.Novel
	if err = cursor.All(ctx, &novels); err != nil {
		return nil, err
	}

	// 并行处理每个小说的额外数据
	for _, novel := range novels {
		novel := novel // 创建副本避免闭包问题
		pool.Submit(&NovelTask{
			service: s,
			novelID: novel.ID.Hex(),
		})
	}

	// 更新缓存
	if err := s.cache.Set(ctx, cacheKey, novels, 30*time.Minute); err != nil {
		log.Printf("Failed to cache popular novels: %v", err)
	}

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

// FindDeviceByIP 通过IP地址查找设备
func (s *NovelService) FindDeviceByIP(ctx context.Context, ip string) (*models.Device, error) {
	var device models.Device
	err := s.db.GetCollection("devices").FindOne(ctx, bson.M{"ip": ip}).Decode(&device)
	if err == mongo.ErrNoDocuments {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &device, nil
}

// CreateNewDevice 创建新的设备记录
func (s *NovelService) CreateNewDevice(ctx context.Context, ip string, userAgent string) (*models.Device, error) {
	deviceID := uuid.New().String()
	device := &models.Device{
		ID:         deviceID,
		IP:         ip,
		UserAgent:  userAgent,
		DeviceType: getDeviceType(userAgent),
		FirstSeen:  time.Now(),
		LastSeen:   time.Now(),
	}

	_, err := s.db.GetCollection("devices").InsertOne(ctx, device)
	if err != nil {
		return nil, err
	}

	return device, nil
}

// GetOrCreateDevice 获取或创建设备信息
func (s *NovelService) GetOrCreateDevice(ctx context.Context, deviceID string, ip string, userAgent string) (*models.Device, error) {
	var device models.Device
	collection := s.db.GetCollection("devices")

	// 尝试查找现有设备
	err := collection.FindOne(ctx, bson.M{"_id": deviceID}).Decode(&device)
	if err != nil {
		if err != mongo.ErrNoDocuments {
			return nil, err
		}
		// 创建新设备
		device = models.Device{
			ID:         deviceID,
			IP:         ip,
			UserAgent:  userAgent,
			DeviceType: getDeviceType(userAgent),
			FirstSeen:  time.Now(),
			LastSeen:   time.Now(),
		}

		_, err = collection.InsertOne(ctx, device)
		if err != nil {
			return nil, err
		}
	} else {
		// 更新最后访问时间和IP
		_, err = collection.UpdateOne(ctx,
			bson.M{"_id": deviceID},
			bson.M{
				"$set": bson.M{
					"ip":        ip,
					"userAgent": userAgent,
					"lastSeen":  time.Now(),
				},
			},
		)
		if err != nil {
			return nil, err
		}
	}

	return &device, nil
}

// GetUserBookmarks 获取用户书签
func (s *NovelService) GetUserBookmarks(ctx context.Context, deviceID string) ([]models.Bookmark, error) {
	var bookmarks []models.Bookmark
	opts := options.Find().SetSort(bson.D{{Key: "createdAt", Value: -1}})

	cursor, err := s.db.GetCollection("bookmarks").Find(ctx,
		bson.M{"deviceId": deviceID},
		opts,
	)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	if err = cursor.All(ctx, &bookmarks); err != nil {
		return nil, err
	}
	return bookmarks, nil
}

// GetReadHistory 获取用户的阅读历史
func (s *NovelService) GetReadHistory(ctx context.Context, deviceID string) ([]models.ReadHistory, error) {
	var histories []models.ReadHistory
	cacheKey := cache.ReadHistoryKey + deviceID

	// 尝试从缓存获取
	err := s.cache.Get(ctx, cacheKey, &histories)
	if err == nil && len(histories) > 0 {
		return histories, nil
	}

	// 从数据库获取
	opts := options.Find().SetSort(bson.D{{Key: "lastRead", Value: -1}})
	cursor, err := s.db.GetCollection("read_history").Find(ctx, bson.M{"deviceId": deviceID}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	if err = cursor.All(ctx, &histories); err != nil {
		return nil, err
	}

	// 设置缓存
	s.cache.Set(ctx, cacheKey, histories, time.Hour)
	return histories, nil
}

// UpsertReadHistory 添加或更新阅读历史
func (s *NovelService) UpsertReadHistory(ctx context.Context, deviceID string, novelID string, lastRead *time.Time) error {
	now := time.Now()
	if lastRead == nil {
		lastRead = &now
	}

	// 使用 upsert 操作,如果存在则更新 lastRead
	filter := bson.M{
		"deviceId": deviceID,
		"novelId":  novelID,
	}
	update := bson.M{
		"$set": bson.M{
			"lastRead": lastRead,
		},
		"$setOnInsert": bson.M{
			"_id": primitive.NewObjectID(),
		},
	}
	opts := options.Update().SetUpsert(true)

	_, err := s.db.GetCollection("read_history").UpdateOne(ctx, filter, update, opts)
	if err != nil {
		return err
	}

	// 删除缓存
	s.cache.Delete(ctx, cache.ReadHistoryKey+deviceID)
	return nil
}

// DeleteReadHistory 删除单条阅读历史
func (s *NovelService) DeleteReadHistory(ctx context.Context, deviceID string, novelID string) error {
	filter := bson.M{
		"deviceId": deviceID,
		"novelId":  novelID,
	}

	_, err := s.db.GetCollection("read_history").DeleteOne(ctx, filter)
	if err != nil {
		return err
	}

	// 删除相关缓存
	s.cache.Delete(ctx, cache.ReadHistoryKey+deviceID)
	s.cache.Delete(ctx, cache.ReadProgressKey+deviceID+":"+novelID)
	return nil
}

// ClearReadHistory 清空用户的阅读历史
func (s *NovelService) ClearReadHistory(ctx context.Context, deviceID string) error {
	filter := bson.M{"deviceId": deviceID}

	// 获取所有要删除的记录的 novelID
	var histories []models.ReadHistory
	cursor, err := s.db.GetCollection("read_history").Find(ctx, filter)
	if err != nil {
		return err
	}
	defer cursor.Close(ctx)

	if err = cursor.All(ctx, &histories); err != nil {
		return err
	}

	// 删除阅读历史
	_, err = s.db.GetCollection("read_history").DeleteMany(ctx, filter)
	if err != nil {
		return err
	}

	// 删除阅读进度
	_, err = s.db.GetCollection("read_progress").DeleteMany(ctx, filter)
	if err != nil {
		return err
	}

	// 删除相关缓存
	s.cache.Delete(ctx, cache.ReadHistoryKey+deviceID)
	for _, history := range histories {
		s.cache.Delete(ctx, cache.ReadProgressKey+deviceID+":"+history.NovelID)
	}

	return nil
}

// GetReadProgress 获取阅读进度
func (s *NovelService) GetReadProgress(ctx context.Context, deviceID string, novelID string) (*models.ReadProgress, error) {
	var progress models.ReadProgress
	cacheKey := cache.ReadProgressKey + deviceID + ":" + novelID

	// 尝试从缓存获取
	err := s.cache.Get(ctx, cacheKey, &progress)
	if err == nil && !progress.ID.IsZero() {
		return &progress, nil
	}

	// 从数据库获取
	err = s.db.GetCollection("read_progress").FindOne(ctx, bson.M{
		"deviceId": deviceID,
		"novelId":  novelID,
	}).Decode(&progress)

	if err == mongo.ErrNoDocuments {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}

	// 设置缓存
	s.cache.Set(ctx, cacheKey, progress, time.Hour)
	return &progress, nil
}

// UpdateReadProgress 更新阅读进度
func (s *NovelService) UpdateReadProgress(ctx context.Context, deviceID string, novelID string, volumeNumber int, chapterNumber int, position int) error {
	now := time.Now()

	// 使用 upsert 操作
	filter := bson.M{
		"deviceId": deviceID,
		"novelId":  novelID,
	}
	update := bson.M{
		"$set": bson.M{
			"volumeNumber":  volumeNumber,
			"chapterNumber": chapterNumber,
			"position":      position,
			"updatedAt":     now,
		},
		"$setOnInsert": bson.M{
			"_id": primitive.NewObjectID(),
		},
	}
	opts := options.Update().SetUpsert(true)

	_, err := s.db.GetCollection("read_progress").UpdateOne(ctx, filter, update, opts)
	if err != nil {
		return err
	}

	// 更新阅读历史
	err = s.UpsertReadHistory(ctx, deviceID, novelID, nil)
	if err != nil {
		return err
	}

	// 删除缓存
	s.cache.Delete(ctx, cache.ReadProgressKey+deviceID+":"+novelID)
	return nil
}

// DeleteReadProgress 删除阅读进度
func (s *NovelService) DeleteReadProgress(ctx context.Context, deviceID string, novelID string) error {
	filter := bson.M{
		"deviceId": deviceID,
		"novelId":  novelID,
	}

	_, err := s.db.GetCollection("read_progress").DeleteOne(ctx, filter)
	if err != nil {
		return err
	}

	// 删除相关缓存
	s.cache.Delete(ctx, cache.ReadProgressKey+deviceID+":"+novelID)
	return nil
}

// 辅助函数：根据UserAgent判断设备类型
func getDeviceType(userAgent string) string {
	userAgent = strings.ToLower(userAgent)
	switch {
	case strings.Contains(userAgent, "mobile") || strings.Contains(userAgent, "android") || strings.Contains(userAgent, "iphone"):
		return "mobile"
	case strings.Contains(userAgent, "ipad") || strings.Contains(userAgent, "tablet"):
		return "tablet"
	default:
		return "pc"
	}
}

// GetNovelsByIDs 批量获取小说信息
func (s *NovelService) GetNovelsByIDs(ctx context.Context, ids []string) (map[string]*models.Novel, error) {
	result := make(map[string]*models.Novel)
	notFound := make([]string, 0)

	// 先从缓存批量获取
	for _, id := range ids {
		var novel models.Novel
		cacheKey := fmt.Sprintf("%s:%s", cache.NovelDetailKey, id)
		if err := s.cache.Get(ctx, cacheKey, &novel); err == nil {
			result[id] = &novel
		} else {
			notFound = append(notFound, id)
		}
	}

	// 如果所有数据都在缓存中找到，直接返回
	if len(notFound) == 0 {
		return result, nil
	}

	// 从数据库批量获取未命中缓存的数据
	filter := bson.M{"_id": bson.M{"$in": notFound}}
	cursor, err := s.db.GetCollection("novels").Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var novels []models.Novel
	if err = cursor.All(ctx, &novels); err != nil {
		return nil, err
	}

	// 将数据库查询结果写入缓存并添加到结果集
	for i := range novels {
		novel := &novels[i]
		result[novel.ID.Hex()] = novel
		cacheKey := fmt.Sprintf("%s:%s", cache.NovelDetailKey, novel.ID.Hex())
		s.cache.Set(ctx, cacheKey, novel, 24*time.Hour)
	}

	return result, nil
}

// GetChaptersByNovelID 批量获取小说的所有章节
func (s *NovelService) GetChaptersByNovelID(ctx context.Context, novelID string) (map[int]map[int]*models.Chapter, error) {
	result := make(map[int]map[int]*models.Chapter)

	// 查询所有章节
	filter := bson.M{"novelId": novelID}
	cursor, err := s.db.GetCollection("chapters").Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var chapters []models.Chapter
	if err = cursor.All(ctx, &chapters); err != nil {
		return nil, err
	}

	// 按卷号和章节号组织数据
	for i := range chapters {
		chapter := &chapters[i]
		if _, ok := result[chapter.VolumeNumber]; !ok {
			result[chapter.VolumeNumber] = make(map[int]*models.Chapter)
		}
		result[chapter.VolumeNumber][chapter.ChapterNumber] = chapter

		// 设置缓存
		cacheKey := fmt.Sprintf("%s:%s:%d:%d", cache.ChapterKey, novelID, chapter.VolumeNumber, chapter.ChapterNumber)
		s.cache.Set(ctx, cacheKey, chapter, 24*time.Hour)
	}

	return result, nil
}

// IncrementNovelReadCountBatch 批量增加小说阅读量
func (s *NovelService) IncrementNovelReadCountBatch(ctx context.Context, novelIDs []string) error {
	if len(novelIDs) == 0 {
		return nil
	}

	// 批量更新阅读量
	filter := bson.M{"_id": bson.M{"$in": novelIDs}}
	update := bson.M{"$inc": bson.M{"readCount": 1}}
	_, err := s.db.GetCollection("novels").UpdateMany(ctx, filter, update)
	if err != nil {
		return err
	}

	// 删除相关缓存
	for _, id := range novelIDs {
		cacheKey := fmt.Sprintf("%s:%s", cache.NovelDetailKey, id)
		s.cache.Delete(ctx, cacheKey)
	}
	// 删除热门小说缓存
	s.cache.Delete(ctx, fmt.Sprintf("%s:%d", cache.PopularNovelsKey, 10))

	return nil
}

// CreateBookmark 创建书签
func (s *NovelService) CreateBookmark(ctx context.Context, deviceID string, novelID string, volumeNumber int, chapterNumber int, position int, note string) (*models.Bookmark, error) {
	// 检查小说是否存在
	_, err := s.GetNovelByID(ctx, novelID)
	if err != nil {
		return nil, err
	}

	// 检查章节是否存在
	_, err = s.GetChapterByNumber(ctx, novelID, volumeNumber, chapterNumber)
	if err != nil {
		return nil, err
	}

	bookmark := &models.Bookmark{
		ID:            primitive.NewObjectID(),
		DeviceID:      deviceID,
		NovelID:       novelID,
		VolumeNumber:  volumeNumber,
		ChapterNumber: chapterNumber,
		Position:      position,
		Note:          note,
		CreatedAt:     time.Now(),
		UpdatedAt:     time.Now(),
	}

	_, err = s.db.GetCollection("bookmarks").InsertOne(ctx, bookmark)
	if err != nil {
		return nil, err
	}

	// 清除相关缓存
	cacheKey := fmt.Sprintf("%s:%s", cache.BookmarkKey, deviceID)
	s.cache.Delete(ctx, cacheKey)

	return bookmark, nil
}

// DeleteBookmark 删除书签
func (s *NovelService) DeleteBookmark(ctx context.Context, deviceID string, bookmarkID string) error {
	objectID, err := primitive.ObjectIDFromHex(bookmarkID)
	if err != nil {
		return errors.NewError(errors.ErrInvalidParameter)
	}

	result, err := s.db.GetCollection("bookmarks").DeleteOne(ctx, bson.M{
		"_id":      objectID,
		"deviceId": deviceID,
	})
	if err != nil {
		return err
	}

	if result.DeletedCount == 0 {
		return errors.NewError(errors.ErrNotFound)
	}

	// 清除相关缓存
	cacheKey := fmt.Sprintf("%s:%s", cache.BookmarkKey, deviceID)
	s.cache.Delete(ctx, cacheKey)

	return nil
}

// UpdateBookmark 更新书签
func (s *NovelService) UpdateBookmark(ctx context.Context, deviceID string, bookmarkID string, note string) (*models.Bookmark, error) {
	objectID, err := primitive.ObjectIDFromHex(bookmarkID)
	if err != nil {
		return nil, errors.NewError(errors.ErrInvalidParameter)
	}

	update := bson.M{
		"$set": bson.M{
			"note":      note,
			"updatedAt": time.Now(),
		},
	}

	var bookmark models.Bookmark
	err = s.db.GetCollection("bookmarks").FindOneAndUpdate(
		ctx,
		bson.M{
			"_id":      objectID,
			"deviceId": deviceID,
		},
		update,
		options.FindOneAndUpdate().SetReturnDocument(options.After),
	).Decode(&bookmark)

	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, errors.NewError(errors.ErrNotFound)
		}
		return nil, err
	}

	// 清除相关缓存
	cacheKey := fmt.Sprintf("%s:%s", cache.BookmarkKey, deviceID)
	s.cache.Delete(ctx, cacheKey)

	return &bookmark, nil
}

// GetUserFavorites 获取用户收藏的小说列表
func (s *NovelService) GetUserFavorites(ctx context.Context, deviceID string) ([]models.Favorite, error) {
	var favorites []models.Favorite
	cacheKey := cache.FavoriteKey + deviceID

	// 尝试从缓存获取
	err := s.cache.Get(ctx, cacheKey, &favorites)
	if err == nil && len(favorites) > 0 {
		return favorites, nil
	}

	// 从数据库获取
	opts := options.Find().SetSort(bson.D{{Key: "createdAt", Value: -1}})
	cursor, err := s.db.GetCollection("favorites").Find(ctx,
		bson.M{"deviceId": deviceID},
		opts,
	)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	if err = cursor.All(ctx, &favorites); err != nil {
		return nil, err
	}

	// 设置缓存
	s.cache.Set(ctx, cacheKey, favorites, s.cfg.Cache.FavoriteList)
	return favorites, nil
}

// AddFavorite 添加收藏
func (s *NovelService) AddFavorite(ctx context.Context, deviceID string, novelID string) error {
	// 检查小说是否存在
	_, err := s.GetNovelByID(ctx, novelID)
	if err != nil {
		return err
	}

	favorite := &models.Favorite{
		ID:        primitive.NewObjectID(),
		DeviceID:  deviceID,
		NovelID:   novelID,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	_, err = s.db.GetCollection("favorites").InsertOne(ctx, favorite)
	if err != nil {
		if mongo.IsDuplicateKeyError(err) {
			return errors.NewError(errors.ErrAlreadyExists)
		}
		return err
	}

	// 清除相关缓存
	s.cache.Delete(ctx, cache.FavoriteKey+deviceID)
	return nil
}

// RemoveFavorite 取消收藏
func (s *NovelService) RemoveFavorite(ctx context.Context, deviceID string, novelID string) error {
	result, err := s.db.GetCollection("favorites").DeleteOne(ctx, bson.M{
		"deviceId": deviceID,
		"novelId":  novelID,
	})
	if err != nil {
		return err
	}

	if result.DeletedCount == 0 {
		return errors.NewError(errors.ErrNotFound)
	}

	// 清除相关缓存
	s.cache.Delete(ctx, cache.FavoriteKey+deviceID)
	return nil
}

// IsFavorite 检查是否已收藏
func (s *NovelService) IsFavorite(ctx context.Context, deviceID string, novelID string) (bool, error) {
	var favorite models.Favorite
	err := s.db.GetCollection("favorites").FindOne(ctx, bson.M{
		"deviceId": deviceID,
		"novelId":  novelID,
	}).Decode(&favorite)

	if err == nil {
		return true, nil
	}
	if err == mongo.ErrNoDocuments {
		return false, nil
	}
	return false, err
}

// GetUserProfile 获取用户资料
func (s *NovelService) GetUserProfile(ctx context.Context, deviceID string) (*models.User, error) {
	cacheKey := cache.UserKey + deviceID

	// 尝试从缓存获取
	var user models.User
	err := s.cache.Get(ctx, cacheKey, &user)
	if err == nil && user.ID != "" {
		return &user, nil
	}

	// 缓存未命中，从数据库获取
	collection := s.db.GetCollection("users")
	err = collection.FindOne(ctx, bson.M{"_id": deviceID}).Decode(&user)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			// 用户不存在，创建默认用户
			now := time.Now()
			user = models.User{
				ID:           deviceID,
				Name:         "用户" + deviceID[0:6],
				Avatar:       "/static/avatars/default.png",
				CreatedAt:    now,
				UpdatedAt:    now,
				LastActiveAt: now,
			}

			_, err = collection.InsertOne(ctx, user)
			if err != nil {
				return nil, err
			}
		} else {
			return nil, err
		}
	}

	// 添加到缓存
	s.cache.Set(ctx, cacheKey, user, s.cfg.Cache.User)

	return &user, nil
}

// UpdateUserProfile 更新用户资料
func (s *NovelService) UpdateUserProfile(ctx context.Context, deviceID string, name string, avatar string) (*models.User, error) {
	collection := s.db.GetCollection("users")

	update := bson.M{
		"$set": bson.M{
			"updatedAt":    time.Now(),
			"lastActiveAt": time.Now(),
		},
	}

	if name != "" {
		update["$set"].(bson.M)["name"] = name
	}

	if avatar != "" {
		update["$set"].(bson.M)["avatar"] = avatar
	}

	opts := options.FindOneAndUpdate().SetReturnDocument(options.After)
	var updatedUser models.User

	err := collection.FindOneAndUpdate(
		ctx,
		bson.M{"_id": deviceID},
		update,
		opts,
	).Decode(&updatedUser)

	if err != nil {
		return nil, err
	}

	// 更新缓存
	cacheKey := cache.UserKey + deviceID
	s.cache.Set(ctx, cacheKey, updatedUser, s.cfg.Cache.User)

	return &updatedUser, nil
}

// GetComments 获取章节评论
func (s *NovelService) GetComments(ctx context.Context, novelID string, volumeNumber, chapterNumber, page, size int) ([]models.CommentResponse, int64, error) {
	cacheKey := fmt.Sprintf("%s%s:%d:%d:%d:%d", cache.CommentListKey, novelID, volumeNumber, chapterNumber, page, size)

	var commentResponses []models.CommentResponse
	err := s.cache.Get(ctx, cacheKey, &commentResponses)
	if err == nil && len(commentResponses) > 0 {
		// 从缓存获取总数
		var total int64
		totalKey := fmt.Sprintf("%s%s:%d:%d:total", cache.CommentListKey, novelID, volumeNumber, chapterNumber)
		s.cache.Get(ctx, totalKey, &total)
		return commentResponses, total, nil
	}

	// 缓存未命中，查询数据库
	collection := s.db.GetCollection("comments")

	// 查询条件
	filter := bson.M{
		"novelId":       novelID,
		"volumeNumber":  volumeNumber,
		"chapterNumber": chapterNumber,
	}

	// 查询总数
	total, err := collection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, err
	}

	// 查询评论列表
	opts := options.Find().
		SetSort(bson.M{"createdAt": -1}).
		SetSkip(int64((page - 1) * size)).
		SetLimit(int64(size))

	cursor, err := collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	var comments []models.Comment
	if err = cursor.All(ctx, &comments); err != nil {
		return nil, 0, err
	}

	// 获取用户信息
	userCollection := s.db.GetCollection("users")
	commentResponses = make([]models.CommentResponse, 0, len(comments))

	for _, comment := range comments {
		var user models.User
		err := userCollection.FindOne(ctx, bson.M{"_id": comment.DeviceID}).Decode(&user)
		if err != nil {
			user.Name = "已删除用户"
			user.Avatar = "/static/avatars/default.png"
		}

		commentResponse := models.CommentResponse{
			ID:            comment.ID,
			UserID:        comment.DeviceID,
			UserName:      user.Name,
			UserAvatar:    user.Avatar,
			NovelID:       comment.NovelID,
			VolumeNumber:  comment.VolumeNumber,
			ChapterNumber: comment.ChapterNumber,
			Content:       comment.Content,
			CreatedAt:     comment.CreatedAt,
		}

		commentResponses = append(commentResponses, commentResponse)
	}

	// 存入缓存
	s.cache.Set(ctx, cacheKey, commentResponses, s.cfg.Cache.Comment)
	totalKey := fmt.Sprintf("%s%s:%d:%d:total", cache.CommentListKey, novelID, volumeNumber, chapterNumber)
	s.cache.Set(ctx, totalKey, total, s.cfg.Cache.Comment)

	return commentResponses, total, nil
}

// CreateComment 创建评论
func (s *NovelService) CreateComment(ctx context.Context, deviceID, novelID string, volumeNumber, chapterNumber int, content string) (*models.Comment, error) {
	// 验证小说和章节是否存在
	chapter, err := s.GetChapterByNumber(ctx, novelID, volumeNumber, chapterNumber)
	if err != nil {
		return nil, errors.NewError(errors.ErrChapterNotFound)
	}

	if chapter == nil {
		return nil, errors.NewError(errors.ErrChapterNotFound)
	}

	// 创建评论
	now := time.Now()
	comment := models.Comment{
		ID:            primitive.NewObjectID(),
		DeviceID:      deviceID,
		NovelID:       novelID,
		VolumeNumber:  volumeNumber,
		ChapterNumber: chapterNumber,
		Content:       content,
		CreatedAt:     now,
		UpdatedAt:     now,
	}

	// 插入数据库
	collection := s.db.GetCollection("comments")
	_, err = collection.InsertOne(ctx, comment)
	if err != nil {
		return nil, err
	}

	// 清除相关缓存
	pattern := fmt.Sprintf("%s%s:%d:%d:*", cache.CommentListKey, novelID, volumeNumber, chapterNumber)
	s.cache.DeleteByPattern(ctx, pattern)

	// 更新用户最后活跃时间
	s.updateUserLastActive(ctx, deviceID)

	return &comment, nil
}

// DeleteComment 删除评论
func (s *NovelService) DeleteComment(ctx context.Context, deviceID, commentID string) error {
	id, err := primitive.ObjectIDFromHex(commentID)
	if err != nil {
		return errors.NewError(errors.ErrInvalidParameter)
	}

	// 查询评论
	collection := s.db.GetCollection("comments")
	var comment models.Comment

	err = collection.FindOne(ctx, bson.M{
		"_id":      id,
		"deviceId": deviceID, // 确保只能删除自己的评论
	}).Decode(&comment)

	if err != nil {
		if err == mongo.ErrNoDocuments {
			return errors.NewError(errors.ErrNotFound)
		}
		return err
	}

	// 删除评论
	_, err = collection.DeleteOne(ctx, bson.M{"_id": id})
	if err != nil {
		return err
	}

	// 清除相关缓存
	pattern := fmt.Sprintf("%s%s:%d:%d:*", cache.CommentListKey, comment.NovelID, comment.VolumeNumber, comment.ChapterNumber)
	s.cache.DeleteByPattern(ctx, pattern)

	return nil
}

// 辅助方法

// updateUserLastActive 更新用户最后活跃时间
func (s *NovelService) updateUserLastActive(ctx context.Context, deviceID string) {
	collection := s.db.GetCollection("users")

	_, err := collection.UpdateOne(
		ctx,
		bson.M{"_id": deviceID},
		bson.M{
			"$set": bson.M{
				"lastActiveAt": time.Now(),
			},
		},
	)

	if err != nil {
		// 记录错误但不返回
		log.Printf("Failed to update user last active time: %v", err)
	}

	// 更新缓存
	cacheKey := cache.UserKey + deviceID
	s.cache.Delete(ctx, cacheKey)
}
