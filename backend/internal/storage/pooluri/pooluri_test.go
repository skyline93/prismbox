package pooluri

import (
	"path/filepath"
	"testing"
)

func TestParseLocal(t *testing.T) {
	scheme, path, err := Parse("local:///app/data/pool1")
	if err != nil {
		t.Fatalf("Parse: %v", err)
	}
	if scheme != "local" {
		t.Errorf("scheme = %q, want local", scheme)
	}
	if path == "" || !filepath.IsAbs(path) {
		t.Errorf("path = %q, want absolute", path)
	}
}

func TestPathFromLocation(t *testing.T) {
	path, err := PathFromLocation("local:///app/data/pool1")
	if err != nil {
		t.Fatalf("PathFromLocation: %v", err)
	}
	if path == "" || !filepath.IsAbs(path) {
		t.Errorf("path = %q, want absolute", path)
	}
}

func TestBuildLocal(t *testing.T) {
	loc, err := BuildLocal("/app/data/pool1")
	if err != nil {
		t.Fatalf("BuildLocal: %v", err)
	}
	if len(loc) < 10 || loc[:9] != "local:///" {
		t.Errorf("BuildLocal = %q, want local:///...", loc)
	}
	_, _, err = Parse(loc)
	if err != nil {
		t.Errorf("Parse(BuildLocal result): %v", err)
	}
}

func TestBuildLocalRelative(t *testing.T) {
	loc, err := BuildLocal("./data/pool1")
	if err != nil {
		t.Fatalf("BuildLocal: %v", err)
	}
	scheme, path, err := Parse(loc)
	if err != nil {
		t.Fatalf("Parse: %v", err)
	}
	if scheme != "local" || !filepath.IsAbs(path) {
		t.Errorf("scheme=%q path=%q", scheme, path)
	}
}

func TestParseRejectsInvalid(t *testing.T) {
	// local:path（无 //）时 Path 为空，会触发 must have path 错误
	_, _, err := Parse("local:data/pool1")
	if err == nil {
		t.Fatal("Parse(local:data/pool1) should fail (no path or invalid)")
	}
	// 格式错误：无 scheme
	_, _, err = Parse("/only/path")
	if err == nil {
		t.Fatal("Parse(/only/path) should fail (no scheme)")
	}
}

func TestValidateLocalPath(t *testing.T) {
	dir := t.TempDir()
	if err := ValidateLocalPath(dir); err != nil {
		t.Errorf("ValidateLocalPath(absolute dir): %v", err)
	}
	// 不存在的路径也通过（不再校验存在性）
	if err := ValidateLocalPath(filepath.Join(dir, "nonexistent")); err != nil {
		t.Errorf("ValidateLocalPath(nonexistent absolute): %v", err)
	}
	// 相对路径应失败
	if err := ValidateLocalPath("./data"); err == nil {
		t.Error("ValidateLocalPath(relative) should fail")
	}
}
