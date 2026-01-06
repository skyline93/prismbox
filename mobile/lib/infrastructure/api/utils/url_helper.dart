/// URL工具类
class UrlHelper {
  /// 清理URL
  static String sanitizeUrl(String url) {
    url = url.trim();

    // 移除末尾的斜杠
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    // 如果没有协议，添加https://
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    return url;
  }

  /// 确保URL以指定路径结尾
  static String ensureEndsWith(String url, String suffix) {
    if (url.endsWith(suffix)) {
      return url;
    }
    if (!url.endsWith('/')) {
      url += '/';
    }
    return url + suffix;
  }

  /// 从URL中提取主机名
  static String? extractHost(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return null;
    }
  }
}

