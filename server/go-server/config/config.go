package config

import (
	"log"
	"time"

	"github.com/spf13/viper"
)

type Config struct {
	Server   ServerConfig   `mapstructure:"server"`
	Database DatabaseConfig `mapstructure:"database"`
	Redis    RedisConfig    `mapstructure:"redis"`
	Cache    CacheConfig    `mapstructure:"cache"`
	Rate     RateConfig     `mapstructure:"rate"`
}

type ServerConfig struct {
	Port         string        `mapstructure:"port"`
	ReadTimeout  time.Duration `mapstructure:"readTimeout"`
	WriteTimeout time.Duration `mapstructure:"writeTimeout"`
}

type DatabaseConfig struct {
	URI      string `mapstructure:"uri"`
	Database string `mapstructure:"database"`
	PoolSize int    `mapstructure:"poolSize"`
}

type RedisConfig struct {
	Host     string `mapstructure:"host"`
	Port     string `mapstructure:"port"`
	Password string `mapstructure:"password"`
	DB       int    `mapstructure:"db"`
	PoolSize int    `mapstructure:"poolSize"`
}

type CacheConfig struct {
	RedisURL      string        `yaml:"redis_url"`
	RedisPassword string        `yaml:"redis_password"`
	RedisDB       int           `yaml:"redis_db"`
	NovelList     time.Duration `yaml:"novel_list"`
	NovelDetail   time.Duration `yaml:"novel_detail"`
	VolumeList    time.Duration `yaml:"volume_list"`
	ChapterList   time.Duration `yaml:"chapter_list"`
	Chapter       time.Duration `yaml:"chapter"`
	SearchResult  time.Duration `yaml:"search_result"`
	FavoriteList  time.Duration `yaml:"favorite_list"`
	ChapterDetail time.Duration `yaml:"chapter_detail"`
	LatestNovels  time.Duration `yaml:"latest_novels"`
	PopularNovels time.Duration `yaml:"popular_novels"`
}

type RateConfig struct {
	Limit  float64       `mapstructure:"limit"`  // 每秒请求数
	Burst  int           `mapstructure:"burst"`  // 突发请求数
	Window time.Duration `mapstructure:"window"` // 时间窗口
}

func LoadConfig() *Config {
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath(".")
	viper.AddConfigPath("./config")

	if err := viper.ReadInConfig(); err != nil {
		log.Fatalf("Error reading config file: %s", err)
	}

	var config Config
	if err := viper.Unmarshal(&config); err != nil {
		log.Fatalf("Unable to decode config into struct: %s", err)
	}

	setDefaultConfig(&config)
	return &config
}

func setDefaultConfig(config *Config) {
	if config.Server.Port == "" {
		config.Server.Port = "8080"
	}
	if config.Server.ReadTimeout == 0 {
		config.Server.ReadTimeout = 10 * time.Second
	}
	if config.Server.WriteTimeout == 0 {
		config.Server.WriteTimeout = 10 * time.Second
	}

	if config.Database.PoolSize == 0 {
		config.Database.PoolSize = 100
	}

	if config.Redis.PoolSize == 0 {
		config.Redis.PoolSize = 100
	}

	// 设置默认缓存时间
	if config.Cache.NovelList == 0 {
		config.Cache.NovelList = 15 * time.Minute
	}
	if config.Cache.NovelDetail == 0 {
		config.Cache.NovelDetail = 30 * time.Minute
	}
	if config.Cache.VolumeList == 0 {
		config.Cache.VolumeList = 20 * time.Minute
	}
	if config.Cache.ChapterList == 0 {
		config.Cache.ChapterList = 20 * time.Minute
	}
	if config.Cache.ChapterDetail == 0 {
		config.Cache.ChapterDetail = 1 * time.Hour
	}
	if config.Cache.SearchResult == 0 {
		config.Cache.SearchResult = 10 * time.Minute
	}
	if config.Cache.LatestNovels == 0 {
		config.Cache.LatestNovels = 5 * time.Minute
	}
	if config.Cache.PopularNovels == 0 {
		config.Cache.PopularNovels = 30 * time.Minute
	}

	// 设置默认限流配置
	if config.Rate.Limit == 0 {
		config.Rate.Limit = 100
	}
	if config.Rate.Burst == 0 {
		config.Rate.Burst = 200
	}
	if config.Rate.Window == 0 {
		config.Rate.Window = 1 * time.Second
	}
}
