// core/config.go
package core

import (
	"errors"
	"os"
	"time"
)

type DBConfig struct {
	Type       string
	SQLitePath string
	Host       string
	User       string
	Password   string
	DBName     string
	Port       string
	SSLMode    string
	TimeZone   string
}

type Config struct {
	JWTSecret             []byte
	URLSignerSecret       []byte
	AccessTokenExpiresIn  time.Duration
	RefreshTokenExpiresIn time.Duration
	PublicBaseURL         string
	SignedURLLoadTTL      time.Duration

	DB            DBConfig
	ServerAddress string
	UploadDir     string
}

func LoadConfig() (*Config, error) {
	secret := getEnv("JWT_SECRET", "qwertyuiop")
	urlSignerSecret := getEnv("URL_SIGNER_SECRET", "qazwsxedc")
	publicBaseURL := getEnv("PUBLIC_BASE_URL", "http://localhost:8080")

	ttlStr := getEnv("SIGNED_URL_LOAD_TTL", "1m")
	signedURLLoadTTL, err := time.ParseDuration(ttlStr)
	if err != nil {
		return nil, errors.New("invalid SIGNED_URL_LOAD_TTL format: " + err.Error())
	}

	dbType := getEnv("DB_TYPE", "sqlite")

	var dbConfig DBConfig
	if dbType == "postgres" {
		dbConfig = DBConfig{
			Host:     getEnv("DB_HOST", "localhost"),
			User:     getEnv("DB_USER", "postgres"),
			Password: getEnv("DB_PASSWORD", "password"),
			DBName:   getEnv("DB_NAME", "photo_app_db"),
			Port:     getEnv("DB_PORT", "5432"),
			SSLMode:  getEnv("DB_SSLMODE", "disable"),
			TimeZone: getEnv("DB_TIMEZONE", "Asia/Shanghai"),
		}
	} else {
		dbConfig = DBConfig{
			Type:       "sqlite",
			SQLitePath: getEnv("DB_SQLITE_PATH", "server.db"),
		}
	}

	return &Config{
		JWTSecret:             []byte(secret),
		URLSignerSecret:       []byte(urlSignerSecret),
		AccessTokenExpiresIn:  time.Minute * 30,
		RefreshTokenExpiresIn: time.Hour * 24 * 30,
		PublicBaseURL:         publicBaseURL,
		SignedURLLoadTTL:      signedURLLoadTTL,
		DB:                    dbConfig,
		ServerAddress:         "0.0.0.0:8080",
		UploadDir:             "uploads",
	}, nil
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}
