import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
  
    WorkmanagerPlugin.registerBGProcessingTask(withIdentifier: "com.example.mobile.autobackup")
    WorkmanagerPlugin.registerBGProcessingTask(withIdentifier: "com.example.mobile.create_post")
    WorkmanagerPlugin.registerBGProcessingTask(withIdentifier: "com.example.mobile.periodicCloudSync")

    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
        // 在这里注册所有需要在后台使用的插件
        // 最简单、最推荐的方式是直接调用自动生成的注册类
        GeneratedPluginRegistrant.register(with: registry)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
