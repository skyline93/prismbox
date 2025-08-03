// core/config.go
package core

import (
	"errors"
	"os"
	"time"
)

type Config struct {
	JWTSecret             []byte
	URLSignerSecret       []byte
	AccessTokenExpiresIn  time.Duration
	RefreshTokenExpiresIn time.Duration
	PublicBaseURL         string
	SignedURLLoadTTL      time.Duration

	DatabaseURL   string
	ServerAddress string
	UploadDir     string
}

func LoadConfig() (*Config, error) {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		secret = "qwertyuiop"
		// return nil, errors.New("JWT_SECRET environment variable not set")
	}

	urlSignerSecret := os.Getenv("URL_SIGNER_SECRET")
	if urlSignerSecret == "" {
		urlSignerSecret = "qazwsxedc"
		// return nil, errors.New("URL_SIGNER_SECRET environment variable not set")
	}

	publicBaseURL := os.Getenv("PUBLIC_BASE_URL")
	if publicBaseURL == "" {
		// 在开发环境中可以提供一个默认值
		publicBaseURL = "http://localhost:8080"
	}

	ttlStr := os.Getenv("SIGNED_URL_LOAD_TTL")
	if ttlStr == "" {
		ttlStr = "1m" // 提供一个合理的默认值：1分钟
	}
	signedURLLoadTTL, err := time.ParseDuration(ttlStr)
	if err != nil {
		return nil, errors.New("invalid SIGNED_URL_LOAD_TTL format: " + err.Error())
	}

	return &Config{
		JWTSecret:             []byte(secret),
		URLSignerSecret:       []byte(urlSignerSecret),
		AccessTokenExpiresIn:  time.Minute * 30,
		RefreshTokenExpiresIn: time.Hour * 24 * 30,
		PublicBaseURL:         publicBaseURL,
		SignedURLLoadTTL:      signedURLLoadTTL,
		DatabaseURL:           "server.db",
		ServerAddress:         "0.0.0.0:8080",
		UploadDir:             "uploads",
	}, nil
}
