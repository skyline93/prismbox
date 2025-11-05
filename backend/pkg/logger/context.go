package logger

// ContextKey context key类型
type ContextKey string

const (
	// RequestIDKey request_id的context key
	RequestIDKey ContextKey = "request_id"
	// UserIDKey user_id的context key
	UserIDKey ContextKey = "user_id"
)
