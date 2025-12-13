import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // 注册存储插件
    StoragePlugin.register(with: registrar(forPlugin: "StoragePlugin")!)
    
    // 注册后台任务处理器
    // 必须在应用启动时注册，否则后台任务无法执行
    BackgroundWorkerApiImpl.registerBackgroundWorkers()
    
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
  }
}
