import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 配置通知中心 delegate（iOS 10+）
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    
    GeneratedPluginRegistrant.register(with: self)
    
    // 注册存储插件
    StoragePlugin.register(with: registrar(forPlugin: "StoragePlugin")!)
    
    // 注册后台任务处理器
    // 必须在应用启动时注册，否则后台任务无法执行
    BackgroundWorkerApiImpl.registerBackgroundWorkers()
    
    // 注册自定义插件到 Flutter Engine
    // Note: This generates a deprecation warning but is the standard pattern
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    AppDelegate.registerPlugins(with: controller.engine)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  /// 注册插件到 Flutter Engine
  /// 用于在后台 Engine 中注册必要的插件
  public static func registerPlugins(with engine: FlutterEngine) {
    // 注册后台工作器前台 API
    BackgroundWorkerFgHostApiSetup.setUp(
      binaryMessenger: engine.binaryMessenger,
      api: BackgroundWorkerApiImpl()
    )
    
    // 注册网络连接检查 API
    ConnectivityApiSetup.setUp(
      binaryMessenger: engine.binaryMessenger,
      api: ConnectivityApiImpl()
    )
    
    // 注册缩略图解码 API
    ThumbnailApiSetup.setUp(
      binaryMessenger: engine.binaryMessenger,
      api: ThumbnailApiImpl()
    )
  }
}
