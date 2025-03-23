// ****************************************************************************
//
// @file       novel_handler.go
// @brief      与小说相关的API
//
// @author     KBchulan
// @date       2025/03/21
// @history
// ****************************************************************************

package v1

import (
	"context"
	"lightnovel/internal/service"
	"lightnovel/pkg/errors"
	"lightnovel/pkg/response"
	"log"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

// @title Light Novel API
// @version 1.0
// @description 轻小说阅读API服务
// @BasePath /api/v1
// @schemes http https
// @contact.name API Support
// @contact.email support@example.com
// @license.name MIT
// @license.url https://opensource.org/licenses/MIT
// @securityDefinitions.apikey ApiKeyAuth
// @in header
// @name X-Device-ID
// @description 设备ID用于识别用户，如果未提供则使用客户端IP

// @tag.name novels
// @tag.description 小说相关接口

// @tag.name favorites
// @tag.description 用户收藏相关接口

// @tag.name bookmarks
// @tag.description 用户书签相关接口

// @tag.name reading
// @tag.description 用户阅读记录相关接口

// @tag.name static
// @tag.description 静态资源服务

// @Summary 获取图片资源
// @Description 获取小说章节的图片资源
// @Tags static
// @Accept */*
// @Produce image/jpeg,image/png,image/webp
// @Param path path string true "图片路径，格式：novels/{小说名称}/volume_{卷号}/chapter_{章节号}/{图片序号}.jpg"
// @Success 200 {file} binary "图片文件"
// @Failure 404 {object} response.Response "图片不存在"
// @Failure 500 {object} response.Response "服务器内部错误"
// @Router /novels/{path} [get]

type NovelHandler struct {
	novelService *service.NovelService
}

func NewNovelHandler(novelService *service.NovelService) *NovelHandler {
	return &NovelHandler{novelService: novelService}
}

// @Summary 获取所有小说
// @Description 获取小说列表，支持分页
// @Tags novels
// @Accept json
// @Produce json
// @Param page query int false "页码" default(1) minimum(1)
// @Param size query int false "每页数量" default(10) minimum(1) maximum(50)
// @Success 200 {object} response.PageResponse{data=[]models.Novel} "成功"
// @Failure 400 {object} response.Response "参数错误"
// @Failure 500 {object} response.Response "服务器内部错误"
// @Router /novels [get]
func (h *NovelHandler) GetAllNovels(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	size, _ := strconv.Atoi(c.DefaultQuery("size", "10"))

	novels, total, err := h.novelService.GetAllNovels(c.Request.Context(), page, size)
	if err != nil {
		response.Error(c, err)
		return
	}

	response.SuccessWithPage(c, total, page, size, novels)
}

// @Summary 获取小说详情
// @Description 根据ID获取小说详情
// @Tags novels
// @Accept json
// @Produce json
// @Param id path string true "小说ID"
// @Success 200 {object} models.Novel "成功"
// @Failure 400 {object} response.Response "参数错误"
// @Failure 404 {object} response.Response "小说不存在"
// @Failure 500 {object} response.Response "服务器内部错误"
// @Router /novels/{id} [get]
func (h *NovelHandler) GetNovelByID(c *gin.Context) {
	id := c.Param("id")
	novel, err := h.novelService.GetNovelByID(c.Request.Context(), id)
	if err != nil {
		response.Error(c, err)
		return
	}

	if novel == nil {
		response.Error(c, errors.NewError(errors.ErrNotFound))
		return
	}

	response.Success(c, novel)
}

// @Summary 获取小说卷列表
// @Description 获取指定小说的所有卷列表
// @Tags novels
// @Accept json
// @Produce json
// @Param id path string true "小说ID"
// @Success 200 {object} response.Response{data=[]models.Volume} "成功"
// @Failure 400 {object} response.Response "参数错误"
// @Failure 404 {object} response.Response "小说不存在"
// @Failure 500 {object} response.Response "服务器内部错误"
// @Router /novels/{id}/volumes [get]
func (h *NovelHandler) GetVolumesByNovelID(c *gin.Context) {
	novelID := c.Param("id")
	volumes, err := h.novelService.GetVolumesByNovelID(c.Request.Context(), novelID)
	if err != nil {
		response.Error(c, err)
		return
	}

	response.Success(c, volumes)
}

// @Summary 获取卷的所有章节
// @Description 获取指定卷的所有章节基本信息（不包含内容）
// @Tags novels
// @Accept json
// @Produce json
// @Param id path string true "小说ID"
// @Param volume path int true "卷号"
// @Success 200 {array} models.ChapterInfo
// @Router /novels/{id}/volumes/{volume}/chapters [get]
func (h *NovelHandler) GetChaptersByVolumeID(c *gin.Context) {
	novelID := c.Param("id")
	volumeNumber, err := strconv.Atoi(c.Param("volume"))
	if err != nil {
		response.Error(c, errors.NewError(errors.ErrInvalidParameter))
		return
	}

	chapters, err := h.novelService.GetChaptersByVolumeID(c.Request.Context(), novelID, volumeNumber)
	if err != nil {
		response.Error(c, err)
		return
	}

	response.Success(c, chapters)
}

// @Summary 获取章节内容
// @Description 获取指定章节的详细内容，包含文本内容和图片信息
// @Tags novels
// @Accept json
// @Produce json
// @Param id path string true "小说ID"
// @Param volume path int true "卷号"
// @Param chapter path int true "章节号"
// @Success 200 {object} response.Response{data=models.Chapter} "成功，返回章节内容和图片信息"
// @Success 200 {object} models.Chapter{hasImages=bool,imageCount=int,imagePath=string} "章节内容模型"
// @Failure 400 {object} response.Response "参数错误"
// @Failure 404 {object} response.Response "章节不存在"
// @Failure 500 {object} response.Response "服务器内部错误"
// @Router /novels/{id}/volumes/{volume}/chapters/{chapter} [get]
func (h *NovelHandler) GetChapterByNumber(c *gin.Context) {
	novelID := c.Param("id")
	volumeNumber, err := strconv.Atoi(c.Param("volume"))
	if err != nil {
		response.Error(c, errors.NewError(errors.ErrInvalidParameter))
		return
	}

	chapterNumber, err := strconv.Atoi(c.Param("chapter"))
	if err != nil {
		response.Error(c, errors.NewError(errors.ErrInvalidParameter))
		return
	}

	chapter, err := h.novelService.GetChapterByNumber(c.Request.Context(), novelID, volumeNumber, chapterNumber)
	if err != nil {
		response.Error(c, err)
		return
	}

	if chapter == nil {
		response.Error(c, errors.NewError(errors.ErrNotFound))
		return
	}

	// 异步增加阅读量
	go func() {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		if err := h.novelService.IncrementNovelReadCount(ctx, novelID); err != nil {
			log.Printf("Failed to increment read count for novel %s: %v", novelID, err)
		}
	}()

	response.Success(c, chapter)
}

// @Summary 搜索小说
// @Description 根据关键词搜索小说
// @Tags novels
// @Accept json
// @Produce json
// @Param keyword query string true "搜索关键词"
// @Param page query int false "页码" default(1)
// @Param size query int false "每页数量" default(10)
// @Success 200 {object} response.Response
// @Router /novels/search [get]
func (h *NovelHandler) SearchNovels(c *gin.Context) {
	keyword := c.Query("keyword")
	if keyword == "" {
		response.Error(c, errors.NewError(errors.ErrInvalidParameter))
		return
	}

	// 获取分页参数
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	size, _ := strconv.Atoi(c.DefaultQuery("size", "10"))
	if page < 1 {
		page = 1
	}
	if size < 1 || size > 50 {
		size = 10
	}

	novels, total, err := h.novelService.SearchNovels(c.Request.Context(), keyword, page, size)
	if err != nil {
		response.Error(c, err)
		return
	}

	response.Success(c, gin.H{
		"total": total,
		"items": novels,
		"page":  page,
		"size":  size,
	})
}

// @Summary 获取最新小说
// @Description 获取最新更新的小说列表
// @Tags novels
// @Accept json
// @Produce json
// @Param limit query int false "限制数量" default(10) minimum(1) maximum(100)
// @Success 200 {object} response.Response{data=[]models.Novel} "成功"
// @Failure 400 {object} response.Response "参数错误"
// @Failure 500 {object} response.Response "服务器内部错误"
// @Router /novels/latest [get]
func (h *NovelHandler) GetLatestNovels(c *gin.Context) {
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	novels, err := h.novelService.GetLatestNovels(c.Request.Context(), limit)
	if err != nil {
		response.Error(c, err)
		return
	}

	response.Success(c, novels)
}

// @Summary 获取热门小说
// @Description 获取阅读量最高的小说列表
// @Tags novels
// @Accept json
// @Produce json
// @Param limit query int false "限制数量" default(10) minimum(1) maximum(100)
// @Success 200 {object} response.Response{data=[]models.Novel} "成功"
// @Failure 400 {object} response.Response "参数错误"
// @Failure 500 {object} response.Response "服务器内部错误"
// @Router /novels/popular [get]
func (h *NovelHandler) GetPopularNovels(c *gin.Context) {
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	novels, err := h.novelService.GetPopularNovelsParallel(c.Request.Context(), limit)
	if err != nil {
		response.Error(c, err)
		return
	}

	response.Success(c, novels)
}

// @Summary 获取阅读历史
// @Description 获取用户的阅读历史列表
// @Tags reading
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Param X-Device-ID header string true "设备ID"
// @Success 200 {object} response.Response{data=[]models.ReadHistory} "成功"
// @Failure 400 {object} response.Response "参数错误"
// @Failure 500 {object} response.Response "服务器内部错误"
// @Router /user/reading/history [get]
func (h *NovelHandler) GetReadHistory(c *gin.Context) {
	deviceID := c.GetString("deviceID")
	if deviceID == "" {
		response.Error(c, errors.NewError(errors.ErrInvalidParameter))
		return
	}

	histories, err := h.novelService.GetReadHistory(c.Request.Context(), deviceID)
	if err != nil {
		response.Error(c, err)
		return
	}

	response.Success(c, histories)
}

// @Summary 删除阅读历史
// @Description 删除指定小说的阅读历史
// @Tags reading
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Param X-Device-ID header string true "设备ID"
// @Param novel_id path string true "小说ID"
// @Success 200 {object} response.Response "成功"
// @Failure 400 {object} response.Response "参数错误"
// @Failure 500 {object} response.Response "服务器内部错误"
// @Router /user/reading/history/{novel_id} [delete]
func (h *NovelHandler) DeleteReadHistory(c *gin.Context) {
	deviceID := c.GetString("deviceID")
	novelID := c.Param("novel_id")
	if deviceID == "" || novelID == "" {
		response.Error(c, errors.NewError(errors.ErrInvalidParameter))
		return
	}

	err := h.novelService.DeleteReadHistory(c.Request.Context(), deviceID, novelID)
	if err != nil {
		response.Error(c, err)
		return
	}

	response.Success(c, gin.H{"message": "删除成功"})
}

// @Summary 清空阅读历史
// @Description 清空用户的所有阅读历史
// @Tags reading
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Param X-Device-ID header string true "设备ID"
// @Success 200 {object} response.Response "成功"
// @Failure 400 {object} response.Response "参数错误"
// @Failure 500 {object} response.Response "服务器内部错误"
// @Router /user/reading/history [delete]
func (h *NovelHandler) ClearReadHistory(c *gin.Context) {
	deviceID := c.GetString("deviceID")
	if deviceID == "" {
		response.Error(c, errors.NewError(errors.ErrInvalidParameter))
		return
	}

	err := h.novelService.ClearReadHistory(c.Request.Context(), deviceID)
	if err != nil {
		response.Error(c, err)
		return
	}

	response.Success(c, gin.H{"message": "清空成功"})
}

// @Summary 获取阅读进度
// @Description 获取指定小说的阅读进度
// @Tags reading
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Param X-Device-ID header string true "设备ID"
// @Param novel_id path string true "小说ID"
// @Success 200 {object} response.Response{data=models.ReadProgress} "成功"
// @Failure 400 {object} response.Response "参数错误"
// @Failure 500 {object} response.Response "服务器内部错误"
// @Router /user/reading/progress/{novel_id} [get]
func (h *NovelHandler) GetReadProgress(c *gin.Context) {
	deviceID := c.GetString("deviceID")
	novelID := c.Param("novel_id")
	if deviceID == "" || novelID == "" {
		response.Error(c, errors.NewError(errors.ErrInvalidParameter))
		return
	}

	progress, err := h.novelService.GetReadProgress(c.Request.Context(), deviceID, novelID)
	if err != nil {
		response.Error(c, err)
		return
	}

	response.Success(c, progress)
}

// @Summary 删除阅读进度
// @Description 删除指定小说的阅读进度
// @Tags reading
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Param X-Device-ID header string true "设备ID"
// @Param novel_id path string true "小说ID"
// @Success 200 {object} response.Response "成功"
// @Failure 400 {object} response.Response "参数错误"
// @Failure 500 {object} response.Response "服务器内部错误"
// @Router /user/reading/progress/{novel_id} [delete]
func (h *NovelHandler) DeleteReadProgress(c *gin.Context) {
	deviceID := c.GetString("deviceID")
	novelID := c.Param("novel_id")
	if deviceID == "" || novelID == "" {
		response.Error(c, errors.NewError(errors.ErrInvalidParameter))
		return
	}

	err := h.novelService.DeleteReadProgress(c.Request.Context(), deviceID, novelID)
	if err != nil {
		response.Error(c, err)
		return
	}

	response.Success(c, gin.H{"message": "删除成功"})
}

// UpdateProgressRequest 更新阅读进度请求
type UpdateProgressRequest struct {
	VolumeNumber  int `json:"volumeNumber" binding:"required,min=1"`
	ChapterNumber int `json:"chapterNumber" binding:"required,min=1"`
	Position      int `json:"position" binding:"min=0"`
}

// @Summary 更新阅读进度
// @Description 更新指定小说的阅读进度
// @Tags reading
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Param X-Device-ID header string true "设备ID"
// @Param novel_id path string true "小说ID"
// @Param request body UpdateProgressRequest true "进度信息"
// @Success 200 {object} response.Response "成功"
// @Failure 400 {object} response.Response "参数错误"
// @Failure 500 {object} response.Response "服务器内部错误"
// @Router /user/reading/progress/{novel_id} [put]
func (h *NovelHandler) UpdateReadProgress(c *gin.Context) {
	deviceID := c.GetString("deviceID")
	novelID := c.Param("novel_id")
	if deviceID == "" || novelID == "" {
		response.Error(c, errors.NewError(errors.ErrInvalidParameter))
		return
	}

	var req UpdateProgressRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, errors.NewError(errors.ErrInvalidParameter))
		return
	}

	err := h.novelService.UpdateReadProgress(
		c.Request.Context(),
		deviceID,
		novelID,
		req.VolumeNumber,
		req.ChapterNumber,
		req.Position,
	)
	if err != nil {
		response.Error(c, err)
		return
	}

	response.Success(c, gin.H{"message": "更新成功"})
}

// @Summary 获取用户书签
// @Description 获取用户的所有书签
// @Tags bookmarks
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Param X-Device-ID header string false "设备ID，如果未提供则使用客户端IP"
// @Success 200 {object} response.Response{data=[]models.Bookmark} "成功"
// @Failure 400 {object} response.Response "参数错误"
// @Failure 500 {object} response.Response "服务器内部错误"
// @Router /user/bookmarks [get]
func (h *NovelHandler) GetUserBookmarks(c *gin.Context) {
	deviceID := c.GetString("deviceID")
	bookmarks, err := h.novelService.GetUserBookmarks(c.Request.Context(), deviceID)
	if err != nil {
		response.Error(c, err)
		return
	}

	response.Success(c, bookmarks)
}

// CreateBookmarkRequest 创建书签请求
type CreateBookmarkRequest struct {
	NovelID       string `json:"novelId" binding:"required"`
	VolumeNumber  int    `json:"volumeNumber" binding:"required"`
	ChapterNumber int    `json:"chapterNumber" binding:"required"`
	Position      int    `json:"position"`
	Note          string `json:"note"`
}

// UpdateBookmarkRequest 更新书签请求
type UpdateBookmarkRequest struct {
	Note string `json:"note"`
}

// @Summary 创建书签
// @Description 在指定章节创建书签
// @Tags bookmarks
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Param X-Device-ID header string false "设备ID，如果未提供则使用客户端IP"
// @Param body body CreateBookmarkRequest true "书签信息"
// @Success 200 {object} response.Response{data=models.Bookmark} "成功"
// @Failure 400 {object} response.Response "参数错误"
// @Failure 404 {object} response.Response "小说或章节不存在"
// @Router /user/bookmarks [post]
func (h *NovelHandler) CreateBookmark(c *gin.Context) {
	var req CreateBookmarkRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, errors.NewError(errors.ErrInvalidParameter))
		return
	}

	deviceID := c.GetString("deviceID")
	bookmark, err := h.novelService.CreateBookmark(c.Request.Context(), deviceID, req.NovelID, req.VolumeNumber, req.ChapterNumber, req.Position, req.Note)
	if err != nil {
		response.Error(c, err)
		return
	}

	response.Success(c, bookmark)
}

// @Summary 删除书签
// @Description 删除指定的书签
// @Tags bookmarks
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Param X-Device-ID header string false "设备ID，如果未提供则使用客户端IP"
// @Param id path string true "书签ID"
// @Success 200 {object} response.Response "删除成功"
// @Failure 400 {object} response.Response "参数错误"
// @Failure 404 {object} response.Response "书签不存在"
// @Router /user/bookmarks/{id} [delete]
func (h *NovelHandler) DeleteBookmark(c *gin.Context) {
	deviceID := c.GetString("deviceID")
	bookmarkID := c.Param("id")

	err := h.novelService.DeleteBookmark(c.Request.Context(), deviceID, bookmarkID)
	if err != nil {
		response.Error(c, err)
		return
	}

	response.Success(c, gin.H{"message": "书签已删除"})
}

// @Summary 更新书签
// @Description 更新书签信息（如备注）
// @Tags bookmarks
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Param X-Device-ID header string false "设备ID，如果未提供则使用客户端IP"
// @Param id path string true "书签ID"
// @Param body body UpdateBookmarkRequest true "更新信息"
// @Success 200 {object} response.Response{data=models.Bookmark} "更新成功"
// @Failure 400 {object} response.Response "参数错误"
// @Failure 404 {object} response.Response "书签不存在"
// @Router /user/bookmarks/{id} [put]
func (h *NovelHandler) UpdateBookmark(c *gin.Context) {
	var req UpdateBookmarkRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, errors.NewError(errors.ErrInvalidParameter))
		return
	}

	deviceID := c.GetString("deviceID")
	bookmarkID := c.Param("id")

	bookmark, err := h.novelService.UpdateBookmark(c.Request.Context(), deviceID, bookmarkID, req.Note)
	if err != nil {
		response.Error(c, err)
		return
	}

	response.Success(c, bookmark)
}

// getDeviceAndNovelID 从上下文和参数中获取设备ID和小说ID
func (h *NovelHandler) getDeviceAndNovelID(c *gin.Context) (string, string, error) {
	deviceID := c.GetString("deviceID")
	if deviceID == "" {
		return "", "", errors.NewError(errors.ErrInvalidParameter)
	}

	novelID := c.Param("novel_id")
	if novelID == "" {
		return "", "", errors.NewError(errors.ErrInvalidParameter)
	}

	return deviceID, novelID, nil
}

// @Summary 获取用户收藏列表
// @Description 获取用户收藏的小说列表
// @Tags favorites
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Param X-Device-ID header string true "设备ID"
// @Success 200 {object} response.Response{data=[]models.Novel} "成功"
// @Failure 400 {object} response.Response "请求参数错误"
// @Failure 500 {object} response.Response "服务器内部错误"
// @Router /user/favorites [get]
func (h *NovelHandler) GetUserFavorites(c *gin.Context) {
	deviceID := c.GetString("deviceID")
	if deviceID == "" {
		response.Error(c, errors.NewError(errors.ErrInvalidParameter))
		return
	}

	novels, err := h.novelService.GetUserFavorites(c.Request.Context(), deviceID)
	if err != nil {
		response.Error(c, err)
		return
	}

	response.Success(c, novels)
}

// @Summary 添加收藏
// @Description 添加小说到收藏列表
// @Tags favorites
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Param X-Device-ID header string true "设备ID"
// @Param novel_id path string true "小说ID"
// @Success 200 {object} response.Response "成功"
// @Failure 400 {object} response.Response "请求参数错误"
// @Failure 500 {object} response.Response "服务器内部错误"
// @Router /user/favorites/{novel_id} [post]
func (h *NovelHandler) AddFavorite(c *gin.Context) {
	deviceID := c.GetString("deviceID")
	novelID := c.Param("novel_id")
	if deviceID == "" || novelID == "" {
		response.Error(c, errors.NewError(errors.ErrInvalidParameter))
		return
	}

	err := h.novelService.AddFavorite(c.Request.Context(), deviceID, novelID)
	if err != nil {
		response.Error(c, err)
		return
	}

	response.Success(c, gin.H{"message": "收藏成功"})
}

// @Summary 取消收藏
// @Description 从收藏列表中移除小说
// @Tags favorites
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Param X-Device-ID header string true "设备ID"
// @Param novel_id path string true "小说ID"
// @Success 200 {object} response.Response "成功"
// @Failure 400 {object} response.Response "请求参数错误"
// @Failure 500 {object} response.Response "服务器内部错误"
// @Router /user/favorites/{novel_id} [delete]
func (h *NovelHandler) RemoveFavorite(c *gin.Context) {
	deviceID := c.GetString("deviceID")
	novelID := c.Param("novel_id")
	if deviceID == "" || novelID == "" {
		response.Error(c, errors.NewError(errors.ErrInvalidParameter))
		return
	}

	err := h.novelService.RemoveFavorite(c.Request.Context(), deviceID, novelID)
	if err != nil {
		response.Error(c, err)
		return
	}

	response.Success(c, gin.H{"message": "取消收藏成功"})
}

// @Summary 检查是否已收藏
// @Description 检查小说是否已收藏
// @Tags favorites
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Param X-Device-ID header string true "设备ID"
// @Param novel_id path string true "小说ID"
// @Success 200 {object} response.Response{data=map[string]bool} "成功"
// @Failure 400 {object} response.Response "请求参数错误"
// @Failure 500 {object} response.Response "服务器内部错误"
// @Router /user/favorites/{novel_id}/check [get]
func (h *NovelHandler) IsFavorite(c *gin.Context) {
	deviceID := c.GetString("deviceID")
	novelID := c.Param("novel_id")
	if deviceID == "" || novelID == "" {
		response.Error(c, errors.NewError(errors.ErrInvalidParameter))
		return
	}

	isFavorite, err := h.novelService.IsFavorite(c.Request.Context(), deviceID, novelID)
	if err != nil {
		response.Error(c, err)
		return
	}

	response.Success(c, gin.H{
		"isFavorite": isFavorite,
	})
}

// UpsertHistoryRequest 添加或更新阅读历史请求
type UpsertHistoryRequest struct {
	LastRead *time.Time `json:"lastRead"` // 可选,不传则使用当前时间
}

// @Summary 添加或更新阅读历史
// @Description 添加或更新指定小说的阅读历史
// @Tags reading
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Param X-Device-ID header string true "设备ID"
// @Param novel_id path string true "小说ID"
// @Param request body UpsertHistoryRequest false "阅读历史信息"
// @Success 200 {object} response.Response "成功"
// @Failure 400 {object} response.Response "参数错误"
// @Failure 500 {object} response.Response "服务器内部错误"
// @Router /user/reading/history/{novel_id} [put]
func (h *NovelHandler) UpsertReadHistory(c *gin.Context) {
	deviceID := c.GetString("deviceID")
	novelID := c.Param("novel_id")
	if deviceID == "" || novelID == "" {
		response.Error(c, errors.NewError(errors.ErrInvalidParameter))
		return
	}

	var req UpsertHistoryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		// 忽略绑定错误,使用默认值(当前时间)
		req = UpsertHistoryRequest{}
	}

	err := h.novelService.UpsertReadHistory(c.Request.Context(), deviceID, novelID, req.LastRead)
	if err != nil {
		response.Error(c, err)
		return
	}

	response.Success(c, gin.H{"message": "更新成功"})
}
