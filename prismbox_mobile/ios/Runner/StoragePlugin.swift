import Flutter
import UIKit

public class StoragePlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "app.prismbox/storage",
            binaryMessenger: registrar.messenger()
        )
        let instance = StoragePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getAvailableSpace":
            do {
                let availableSpace = try getAvailableSpace()
                result(availableSpace)
            } catch {
                result(FlutterError(
                    code: "STORAGE_ERROR",
                    message: error.localizedDescription,
                    details: nil
                ))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func getAvailableSpace() throws -> Int64 {
        let fileManager = FileManager.default
        
        // 在 iOS 上，使用文档目录来获取文件系统属性
        // attributesOfFileSystem 会返回整个文件系统的属性，而不仅仅是该目录的属性
        guard let documentsDirectory = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            throw NSError(
                domain: "StoragePlugin",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to get documents directory"]
            )
        }
        
        guard let attributes = try? fileManager.attributesOfFileSystem(
            forPath: documentsDirectory.path
        ) else {
            throw NSError(
                domain: "StoragePlugin",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to get file system attributes"]
            )
        }
        
        if let freeSize = attributes[.systemFreeSize] as? NSNumber {
            return freeSize.int64Value
        }
        
        return 0
    }
}

