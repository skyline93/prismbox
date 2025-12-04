/// 后端统一响应格式
/// 
/// 后端API统一使用以下格式：
/// ```json
/// {
///   "code": 0,      // 0=成功, 1=失败
///   "message": "...",
///   "data": {...}
/// }
/// ```
class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;

  ApiResponse({
    required this.code,
    required this.message,
    this.data,
  });

  /// 判断是否成功
  bool get isSuccess => code == 0;

  /// 从JSON创建ApiResponse
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      code: json['code'] as int,
      message: json['message'] as String,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      if (data != null) 'data': data,
    };
  }

  @override
  String toString() {
    return 'ApiResponse(code: $code, message: $message, data: $data)';
  }
}

