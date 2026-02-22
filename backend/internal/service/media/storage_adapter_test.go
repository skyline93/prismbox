package media

import "testing"

func TestParseThumbnailSize(t *testing.T) {
	tests := []struct {
		name    string
		param   string
		want    ThumbnailTier
		wantErr bool
	}{
		{"empty defaults to thumbnail", "", TierThumbnail, false},
		{"thumbnail", "thumbnail", TierThumbnail, false},
		{"preview", "preview", TierPreview, false},
		{"fullsize", "fullsize", TierFullsize, false},
		{"case insensitive", "PREVIEW", TierPreview, false},
		{"invalid WxH", "200x200", "", true},
		{"invalid single number", "400", "", true},
		{"invalid string", "large", "", true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := ParseThumbnailSize(tt.param)
			if (err != nil) != tt.wantErr {
				t.Errorf("ParseThumbnailSize(%q) err = %v, wantErr %v", tt.param, err, tt.wantErr)
				return
			}
			if !tt.wantErr && got != tt.want {
				t.Errorf("ParseThumbnailSize(%q) = %v, want %v", tt.param, got, tt.want)
			}
		})
	}
}
