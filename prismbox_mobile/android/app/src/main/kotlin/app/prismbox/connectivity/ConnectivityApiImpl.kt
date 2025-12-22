package app.prismbox.connectivity

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.util.Log

private const val TAG = "ConnectivityApiImpl"

/// 网络连接检查 API 实现
/// 实现 ConnectivityApi 接口，处理 Flutter 侧的 API 调用
class ConnectivityApiImpl(private val context: Context) : ConnectivityApi {
    private val ctx: Context = context.applicationContext
    
    private val connectivityManager: ConnectivityManager
        get() = ctx.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    
    private val wifiManager: WifiManager
        get() = ctx.getSystemService(Context.WIFI_SERVICE) as WifiManager

    override fun getNetworkInfo(): NetworkInfo {
        val network = connectivityManager.activeNetwork
        val capabilities = connectivityManager.getNetworkCapabilities(network)
        
        if (capabilities == null) {
            Log.d(TAG, "No active network")
            return NetworkInfo(
                isConnected = false,
                capabilities = emptyList()
            )
        }
        
        val capabilityList = mutableListOf<NetworkCapability>()
        val isConnected = capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
                         capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
        
        // 检查 WiFi
        if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ||
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI_AWARE)) {
            capabilityList.add(NetworkCapability.WIFI)
        }
        
        // 检查移动数据
        if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) {
            capabilityList.add(NetworkCapability.CELLULAR)
        }
        
        // 检查 VPN
        if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) {
            capabilityList.add(NetworkCapability.VPN)
            
            // 如果 VPN 激活但未报告 WiFi 或移动数据，根据 WiFi 是否启用来判断
            if (!capabilityList.contains(NetworkCapability.WIFI) &&
                !capabilityList.contains(NetworkCapability.CELLULAR)) {
                if (wifiManager.isWifiEnabled) {
                    capabilityList.add(NetworkCapability.WIFI)
                } else {
                    capabilityList.add(NetworkCapability.CELLULAR)
                }
            }
        }
        
        // 检查无流量限制
        if (capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED)) {
            capabilityList.add(NetworkCapability.UNMETERED)
        }
        
        Log.d(TAG, "Network info: isConnected=$isConnected, capabilities=$capabilityList")
        
        return NetworkInfo(
            isConnected = isConnected,
            capabilities = capabilityList
        )
    }

    override fun isWifiConnected(): Boolean {
        val networkInfo = getNetworkInfo()
        return networkInfo.isConnected && 
               networkInfo.capabilities.contains(NetworkCapability.WIFI)
    }

    override fun hasNetworkConnection(): Boolean {
        return getNetworkInfo().isConnected
    }
}

