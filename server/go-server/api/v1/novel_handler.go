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
// @Description 获取指定章节的详细内容
// @Tags novels
// @Accept json
// @Produce json
// @Param id path string true "小说ID"
// @Param volume path int true "卷号"
// @Param chapter path int true "章节号"
// @Success 200 {object} models.Chapter
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

// 更新阅读进度请求体
type UpdateProgressRequest struct {
	NovelID       string `json:"novelId" binding:"required"`
	VolumeNumber  int    `json:"volumeNumber" binding:"required"`
	ChapterNumber int    `json:"chapterNumber" binding:"required"`
	Position      int    `json:"position"`
}

// @Summary 获取阅读历史
// @Description 获取用户的阅读历史记录
// @Tags user
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Param X-Device-ID header string false "设备ID，如果未提供则使用客户端IP"
// @Param limit query int false "限制数量" default(10) minimum(1) maximum(100)
// @Success 200 {object} response.Response{data=[]models.ReadingProgress} "成功"
// @Failure 400 {object} response.Response "参数错误"
// @Failure 500 {object} response.Response "服务器内部错误"
// @Router /user/history [get]
func (h *NovelHandler) GetReadingHistory(c *gin.Context) {
	deviceID := c.GetString("deviceID")
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	history, err := h.novelService.GetReadingHistory(c.Request.Context(), deviceID, limit)
	if err != nil {
		response.Error(c, err)
		return
	}

	response.Success(c, history)
}

// @Summary 更新阅读进度
// @Description 更新用户的小说阅读进度
// @Tags user
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Param X-Device-ID header string false "设备ID，如果未提供则使用客户端IP"
// @Param body body UpdateProgressRequest true "阅读进度信息"
// @Success 200 {object} response.Response{data=string} "更新成功"
// @Failure 400 {object} response.Response "参数错误"
// @Failure 404 {object} response.Response "小说不存在"
// @Failure 500 {object} response.Response "服务器内部错误"
// @Router /user/progress [patch]
func (h *NovelHandler) UpdateReadingProgress(c *gin.Context) {
	deviceID := c.GetString("deviceID")
	var req UpdateProgressRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, errors.NewError(errors.ErrInvalidParameter))
		return
	}

	err := h.novelService.UpdateReadingProgress(
		c.Request.Context(),
		deviceID,
		req.NovelID,
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
// @Tags user
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
