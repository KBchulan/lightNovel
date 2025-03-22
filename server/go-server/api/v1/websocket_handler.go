// ****************************************************************************
//
// @file       websocket_handler.go
// @brief      与WebSocket相关的API
//
// @author     KBchulan
// @date       2025/03/21
// @history
// ****************************************************************************

package v1

import (
	"encoding/json"
	"fmt"
	"lightnovel/config"
	ws "lightnovel/pkg/websocket"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
)

// WSMessage WebSocket消息结构
type WSMessage struct {
	Type string      `json:"type"` // "novel_update", "system_notice"
	Data interface{} `json:"data"`
	Time time.Time   `json:"time"`
}

// NovelUpdate 小说更新消息
type NovelUpdate struct {
	NovelID     string `json:"novelId"`
	Title       string `json:"title"`
	UpdateType  string `json:"updateType"` // "new_chapter", "new_volume", "content_update"
	Description string `json:"description"`
}

// SystemNotice 系统通知消息
type SystemNotice struct {
	Level   string `json:"level"`   // "info", "warning", "error"
	Content string `json:"content"` // 通知内容
}

var (
	upgrader = websocket.Upgrader{
		ReadBufferSize:  1024,
		WriteBufferSize: 1024,
		CheckOrigin: func(r *http.Request) bool {
			return true
		},
	}
)

// WebSocketHandler 处理WebSocket连接
type WebSocketHandler struct {
	hub *ws.Hub
	cfg *config.Config
}

// NewWebSocketHandler 创建WebSocket处理器
func NewWebSocketHandler(cfg *config.Config) *WebSocketHandler {
	hub := ws.NewHub()
	go hub.Run()
	return &WebSocketHandler{
		hub: hub,
		cfg: cfg,
	}
}

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

// @tag.name websocket
// @tag.description WebSocket相关接口

// @Summary WebSocket连接
// @Description 建立WebSocket连接以接收实时更新通知
// @Tags websocket
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Param X-Device-ID header string false "设备ID，如果未提供则使用客户端IP"
// @Success 101 {string} string "Switching Protocols"
// @Failure 400 {object} response.Response "无效的请求"
// @Router /api/v1/ws [get]
func (h *WebSocketHandler) HandleConnection(c *gin.Context) {
	deviceID := c.GetString("deviceID")
	if deviceID == "" {
		deviceID = c.ClientIP()
	}

	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	client := ws.NewClient(h.hub, conn)
	client.DeviceID = deviceID

	h.hub.Register <- client

	go client.WritePump()
	go client.ReadPump()
}

// @Summary 获取WebSocket状态
// @Description 获取当前WebSocket连接的状态信息
// @Tags websocket
// @Accept json
// @Produce json
// @Success 200 {object} response.Response{data=map[string]interface{}} "成功"
// @Failure 500 {object} response.Response "服务器内部错误"
// @Router /api/v1/ws/status [get]
func (h *WebSocketHandler) GetStatus(c *gin.Context) {
	status := map[string]interface{}{
		"connections":  h.hub.GetActiveConnections(),
		"messagesSent": h.hub.GetMessagesSent(),
		"uptime":       time.Since(h.hub.GetStartTime()).String(),
	}
	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": status,
	})
}

// BroadcastNovelUpdate 广播小说更新消息
func (h *WebSocketHandler) BroadcastNovelUpdate(novelID string, title string, updateType string) {
	update := NovelUpdate{
		NovelID:     novelID,
		Title:       title,
		UpdateType:  updateType,
		Description: getUpdateDescription(updateType, title),
	}

	msg := WSMessage{
		Type: "novel_update",
		Data: update,
		Time: time.Now(),
	}

	msgBytes, err := json.Marshal(msg)
	if err != nil {
		return
	}

	h.hub.Broadcast <- msgBytes
}

// BroadcastSystemNotice 广播系统通知
func (h *WebSocketHandler) BroadcastSystemNotice(level string, content string) {
	notice := SystemNotice{
		Level:   level,
		Content: content,
	}

	msg := WSMessage{
		Type: "system_notice",
		Data: notice,
		Time: time.Now(),
	}

	msgBytes, err := json.Marshal(msg)
	if err != nil {
		return
	}

	h.hub.Broadcast <- msgBytes
}

// 辅助函数：检查origin是否在允许列表中
func isAllowedOrigin(origin string, allowedOrigins []string) bool {
	if origin == "" {
		return false
	}
	for _, allowed := range allowedOrigins {
		if strings.EqualFold(origin, allowed) {
			return true
		}
	}
	return false
}

// 辅助函数：根据更新类型生成描述
func getUpdateDescription(updateType string, title string) string {
	switch updateType {
	case "new_chapter":
		return fmt.Sprintf("《%s》有新章节更新啦！", title)
	case "new_volume":
		return fmt.Sprintf("《%s》新卷发布！", title)
	case "content_update":
		return fmt.Sprintf("《%s》内容已更新", title)
	default:
		return fmt.Sprintf("《%s》有新的更新", title)
	}
}
