package config

import (
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/album/backend/internal/config/types"
	"github.com/spf13/pflag"
)

func TestLoad_PublicBaseURL_FromConfigFile(t *testing.T) {
	dir := t.TempDir()
	cfgPath := filepath.Join(dir, "config.yaml")
	// 仅配置文件设置
	content := []byte(`server:
  host: "0.0.0.0"
  port: 8080
  public_base_url: "http://from-file:8080"
`)
	if err := os.WriteFile(cfgPath, content, 0644); err != nil {
		t.Fatal(err)
	}

	loader := NewLoader(cfgPath)
	cfg, err := loader.Load(nil)
	if err != nil {
		t.Fatal(err)
	}
	if cfg.Server == nil {
		t.Fatal("Server config is nil")
	}
	if cfg.Server.PublicBaseURL != "http://from-file:8080" {
		t.Errorf("PublicBaseURL = %q, want http://from-file:8080", cfg.Server.PublicBaseURL)
	}
}

func TestLoad_PublicBaseURL_FromEnv(t *testing.T) {
	dir := t.TempDir()
	cfgPath := filepath.Join(dir, "config.yaml")
	// 配置文件不含 server 段，使 server.* 完全来自 env 或默认值
	content := []byte("logger:\n  level: debug\n")
	if err := os.WriteFile(cfgPath, content, 0644); err != nil {
		t.Fatal(err)
	}

	key := "ALBUM_SERVER_PUBLIC_BASE_URL"
	prev, had := os.LookupEnv(key)
	os.Setenv(key, "http://from-env:9090")
	defer func() {
		if had {
			os.Setenv(key, prev)
		} else {
			os.Unsetenv(key)
		}
	}()

	loader := NewLoader(cfgPath)
	cfg, err := loader.Load(nil)
	if err != nil {
		t.Fatal(err)
	}
	if cfg.Server == nil {
		t.Fatal("Server config is nil")
	}
	if cfg.Server.PublicBaseURL != "http://from-env:9090" {
		t.Errorf("PublicBaseURL = %q, want http://from-env:9090", cfg.Server.PublicBaseURL)
	}
}

func TestLoad_PublicBaseURL_UnsetFlagDoesNotOverrideConfig(t *testing.T) {
	dir := t.TempDir()
	cfgPath := filepath.Join(dir, "config.yaml")
	content := []byte(`server:
  host: "0.0.0.0"
  port: 8080
  public_base_url: "http://from-file:8080"
`)
	if err := os.WriteFile(cfgPath, content, 0644); err != nil {
		t.Fatal(err)
	}

	flags := pflag.NewFlagSet("test", pflag.ContinueOnError)
	AddFlags(flags)
	// 不传入 --server.public_base_url，即 flag 未显式设置
	_ = flags.Parse([]string{})

	loader := NewLoader(cfgPath)
	loader.BindPFlags(flags)
	cfg, err := loader.Load(flags)
	if err != nil {
		t.Fatal(err)
	}
	if cfg.Server == nil {
		t.Fatal("Server config is nil")
	}
	// 未显式设置的 flag 不应以默认空串覆盖配置文件
	if cfg.Server.PublicBaseURL != "http://from-file:8080" {
		t.Errorf("PublicBaseURL = %q, want http://from-file:8080 (from config file)", cfg.Server.PublicBaseURL)
	}
}

func TestLoad_PublicBaseURL_ExplicitFlagOverrides(t *testing.T) {
	dir := t.TempDir()
	cfgPath := filepath.Join(dir, "config.yaml")
	content := []byte(`server:
  host: "0.0.0.0"
  port: 8080
  public_base_url: "http://from-file:8080"
`)
	if err := os.WriteFile(cfgPath, content, 0644); err != nil {
		t.Fatal(err)
	}

	flags := pflag.NewFlagSet("test", pflag.ContinueOnError)
	AddFlags(flags)
	_ = flags.Parse([]string{"--server.public_base_url=http://from-flag:7000"})

	loader := NewLoader(cfgPath)
	loader.BindPFlags(flags)
	cfg, err := loader.Load(flags)
	if err != nil {
		t.Fatal(err)
	}
	if cfg.Server == nil {
		t.Fatal("Server config is nil")
	}
	if cfg.Server.PublicBaseURL != "http://from-flag:7000" {
		t.Errorf("PublicBaseURL = %q, want http://from-flag:7000", cfg.Server.PublicBaseURL)
	}
}

func TestLoad_PublicBaseURL_DefaultWhenUnset(t *testing.T) {
	dir := t.TempDir()
	cfgPath := filepath.Join(dir, "config.yaml")
	content := []byte(`server:
  host: "0.0.0.0"
  port: 8080
`)
	if err := os.WriteFile(cfgPath, content, 0644); err != nil {
		t.Fatal(err)
	}

	loader := NewLoader(cfgPath)
	cfg, err := loader.Load(nil)
	if err != nil {
		t.Fatal(err)
	}
	if cfg.Server == nil {
		t.Fatal("Server config is nil")
	}
	// 未在文件/env 设置时使用默认值
	if cfg.Server.PublicBaseURL != "http://127.0.0.1:8080" {
		t.Errorf("PublicBaseURL = %q, want default http://127.0.0.1:8080", cfg.Server.PublicBaseURL)
	}
}

func TestLoad_ServerTimeouts_FromConfigFile(t *testing.T) {
	dir := t.TempDir()
	cfgPath := filepath.Join(dir, "config.yaml")
	content := []byte(`server:
  host: "0.0.0.0"
  port: 8080
  public_base_url: "http://127.0.0.1:8080"
  read_timeout: 2h
  write_timeout: 30m
  idle_timeout: 90s
`)
	if err := os.WriteFile(cfgPath, content, 0644); err != nil {
		t.Fatal(err)
	}

	loader := NewLoader(cfgPath)
	cfg, err := loader.Load(nil)
	if err != nil {
		t.Fatal(err)
	}
	if cfg.Server == nil {
		t.Fatal("Server config is nil")
	}
	// DecodeHook 应在 Unmarshal 阶段正确解析 Duration 字符串
	if cfg.Server.ReadTimeout != types.Duration(2*time.Hour) {
		t.Errorf("ReadTimeout = %v, want 2h", cfg.Server.ReadTimeout)
	}
	if cfg.Server.WriteTimeout != types.Duration(30*time.Minute) {
		t.Errorf("WriteTimeout = %v, want 30m", cfg.Server.WriteTimeout)
	}
	if cfg.Server.IdleTimeout != types.Duration(90*time.Second) {
		t.Errorf("IdleTimeout = %v, want 90s", cfg.Server.IdleTimeout)
	}
}
