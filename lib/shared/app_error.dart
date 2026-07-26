/// Application-specific error types for experience engine failures.
enum AppError {
  contentLoadFailed,
  contentValidationFailed,
  audioFileMissing,
  imageFileMissing,
  invalidStateTransition,
  sessionCreationFailed,
  telemetryWriteFailed,
  exportFailed,
  unknown;

  String get message {
    switch (this) {
      case AppError.contentLoadFailed:
        return '内容配置加载失败';
      case AppError.contentValidationFailed:
        return '内容配置格式错误';
      case AppError.audioFileMissing:
        return '音频文件缺失';
      case AppError.imageFileMissing:
        return '图片文件缺失';
      case AppError.invalidStateTransition:
        return '无效的状态转换';
      case AppError.sessionCreationFailed:
        return '创建测试会话失败';
      case AppError.telemetryWriteFailed:
        return '日志写入失败';
      case AppError.exportFailed:
        return '导出失败';
      case AppError.unknown:
        return '未知错误';
    }
  }
}
