// core/config.go
package core

import (
	"errors"
	"os"
)

type Config struct {
	JWTSecret     []byte
	DatabaseURL   string
	ServerAddress string
	UploadDir     string
}

func LoadConfig() (*Config, error) {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		return nil, errors.New("JWT_SECRET environment variable not set")
	}

	return &Config{
		JWTSecret:     []byte(secret),
		DatabaseURL:   "server.db",
		ServerAddress: "0.0.0.0:8080",
		UploadDir:     "uploads",
	}, nil
}
