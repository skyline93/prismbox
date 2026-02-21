// lib/presentation/widgets/media/duration_formatter.dart

/// 时长格式化工具
///
/// 遵循性能规范：
/// - 所有函数都是纯函数，无副作用
/// - 避免在 build 中创建对象，使用静态方法
class DurationFormatter {
  /// 私有构造函数，防止实例化
  DurationFormatter._();

  /// 将秒数格式化为 MM:SS 格式
  ///
  /// 示例：
  /// - 65 秒 → "1:05"
  /// - 125 秒 → "2:05"
  /// - 3661 秒 → "61:01"
  ///
  /// [seconds] 视频时长（秒），如果为 null 则返回空字符串
  static String formatDuration(int? seconds) {
    if (seconds == null || seconds < 0) {
      return '';
    }

    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    // 使用字符串插值，避免多次字符串拼接
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// 将 Duration 对象格式化为 MM:SS 格式
  ///
  /// [duration] Duration 对象，如果为 null 则返回空字符串
  static String formatDurationObject(Duration? duration) {
    if (duration == null) {
      return '';
    }
    return formatDuration(duration.inSeconds);
  }
}
