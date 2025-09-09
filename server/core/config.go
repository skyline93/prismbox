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
	publicBaseURL := getEnv("PUBLIC_BASE_URL", "http://10.0.2.2:8080")

	ttlStr := getEnv("SIGNED_URL_LOAD_TTL", "30m")
	signedURLLoadTTL, err := time.ParseDuration(ttlStr)
	if err != nil {
		return nil, errors.New("invalid SIGNED_URL_LOAD_TTL format: " + err.Error())
	}

	dbType := getEnv("DB_TYPE", "postgres")

	var dbConfig DBConfig
	if dbType == "postgres" {
		dbConfig = DBConfig{
			Type:     "postgres",
			Host:     getEnv("DB_HOST", "localhost"),
			User:     getEnv("DB_USER", "mobile"),
			Password: getEnv("DB_PASSWORD", "mobile"),
			DBName:   getEnv("DB_NAME", "mobile"),
			Port:     getEnv("DB_PORT", "15422"),
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
