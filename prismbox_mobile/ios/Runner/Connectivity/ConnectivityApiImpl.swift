import Foundation
import Network
import Flutter

/// 网络连接检查 API 实现
/// 实现 ConnectivityApi 接口，处理 Flutter 侧的 API 调用
class ConnectivityApiImpl: ConnectivityApi {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "ConnectivityMonitor")
    
    func getNetworkInfo() throws -> NetworkInfo {
        let semaphore = DispatchSemaphore(value: 0)
        var result: NetworkInfo?
        
        monitor.pathUpdateHandler = { path in
            var capabilities: [NetworkCapability] = []
            var isConnected = false
            
            if path.status == .satisfied {
                isConnected = true
                
                // 检查 WiFi
                if path.usesInterfaceType(.wifi) || path.usesInterfaceType(.wiredEthernet) {
                    capabilities.append(.wifi)
                }
                
                // 检查移动数据
                if path.usesInterfaceType(.cellular) {
                    capabilities.append(.cellular)
                }
                
                // 检查 VPN
                if path.usesInterfaceType(.other) {
                    // iOS 中，VPN 通常通过 .other 接口类型表示
                    // 但需要进一步检查，这里简化处理
                    capabilities.append(.vpn)
                }
                
                // 检查无流量限制（WiFi 通常是无流量限制的）
                if path.isExpensive == false {
                    capabilities.append(.unmetered)
                }
            }
            
            result = NetworkInfo(
                isConnected: isConnected,
                capabilities: capabilities
            )
            
            semaphore.signal()
        }
        
        monitor.start(queue: queue)
        
        // 等待路径更新（最多等待 1 秒）
        if semaphore.wait(timeout: .now() + 1.0) == .timedOut {
            monitor.cancel()
            // 超时返回默认值
            return NetworkInfo(
                isConnected: false,
                capabilities: []
            )
        }
        
        monitor.cancel()
        
        return result ?? NetworkInfo(
            isConnected: false,
            capabilities: []
        )
    }
    
    func isWifiConnected() throws -> Bool {
        let networkInfo = try getNetworkInfo()
        return networkInfo.isConnected && 
               networkInfo.capabilities.contains(.wifi)
    }
    
    func hasNetworkConnection() throws -> Bool {
        return try getNetworkInfo().isConnected
    }
}

