package config

import (
	"os"
	"path/filepath"
)

type Config struct {
	Server   ServerConfig
	Database DatabaseConfig
	Storage  StorageConfig
}

type ServerConfig struct {
	Port string
}

type DatabaseConfig struct {
	URI      string
	Database string
}

type StorageConfig struct {
	NovelBasePath string
}

func LoadConfig() *Config {
	// 获取项目根目录（go-server 的上一级目录）
	rootDir := filepath.Dir(filepath.Dir(getCurrentDir()))

	return &Config{
		Server: ServerConfig{
			Port: getEnvOrDefault("SERVER_PORT", "8080"),
		},
		Database: DatabaseConfig{
			URI:      getEnvOrDefault("MONGO_URI", "mongodb://localhost:27017"),
			Database: getEnvOrDefault("MONGO_DB", "lightnovel"),
		},
		Storage: StorageConfig{
			NovelBasePath: filepath.Join(rootDir, "novels"),
		},
	}
}

func getCurrentDir() string {
	dir, err := os.Getwd()
	if err != nil {
		return ""
	}
	return dir
}

func getEnvOrDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
