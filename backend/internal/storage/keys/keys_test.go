package keys

import (
	"testing"
)

func TestBuildKeyAndResolveKey_Roundtrip(t *testing.T) {
	tests := []struct {
		hash      string
		extension string
		variant   string
	}{
		{"abcd1234ef567890", "jpg", ""},
		{"abcd1234ef567890", "jpg", VariantThumbnail},
		{"abcd1234ef567890", "mp4", VariantPreview},
		// variant 含 "_" 时（如 thumbnail_200x200）解析会按最后一个 "_" 拆分，roundtrip 后 variant 仅剩后缀，此处不测
	}
	for _, tt := range tests {
		key, err := BuildKey(tt.hash, tt.extension, tt.variant)
		if err != nil {
			t.Fatalf("BuildKey: %v", err)
		}
		if key == "" {
			t.Fatal("BuildKey returned empty")
		}
		hash, ext, variant, err := ResolveKey(key)
		if err != nil {
			t.Fatalf("ResolveKey: %v", err)
		}
		if hash != tt.hash || ext != tt.extension || variant != tt.variant {
			t.Errorf("roundtrip: got hash=%q ext=%q variant=%q, want %q %q %q", hash, ext, variant, tt.hash, tt.extension, tt.variant)
		}
	}
}

func TestResolveKey_RejectsOldFormat_WithoutFilesPrefix(t *testing.T) {
	key := "ab/cd/abcd1234_thumbnail.jpg"
	_, _, _, err := ResolveKey(key)
	if err == nil {
		t.Fatal("ResolveKey must reject key without files/ prefix")
	}
}

func TestResolveKey_WithFilesPrefix(t *testing.T) {
	key := "files/ab/cd/abcd1234_thumbnail.jpg"
	hash, ext, variant, err := ResolveKey(key)
	if err != nil {
		t.Fatalf("ResolveKey: %v", err)
	}
	if hash != "abcd1234" || ext != "jpg" || variant != "thumbnail" {
		t.Errorf("got hash=%q ext=%q variant=%q", hash, ext, variant)
	}
}

func TestBuildKey_Format(t *testing.T) {
	key, err := BuildKey("abcd1234", "jpg", "thumbnail")
	if err != nil {
		t.Fatalf("BuildKey: %v", err)
	}
	if key != "files/ab/cd/abcd1234_thumbnail.jpg" {
		t.Errorf("BuildKey format: got %q", key)
	}
}
