package com.u163.glf9832.prismbox

import android.content.Context
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import app.prismbox.HttpSSLOptionsPlugin
import app.prismbox.StoragePlugin
import app.prismbox.background.BackgroundWorkerApiImpl
import app.prismbox.background.BackgroundWorkerFgHostApi
import app.prismbox.connectivity.ConnectivityApiImpl
import app.prismbox.connectivity.ConnectivityApi
import app.prismbox.images.ThumbnailApi
import app.prismbox.images.ThumbnailsImpl

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 注册HttpSSLOptionsPlugin
        flutterEngine.plugins.add(HttpSSLOptionsPlugin())
        
        // 注册StoragePlugin
        flutterEngine.plugins.add(StoragePlugin())
        
        // 注册后台工作器前台 API
        BackgroundWorkerFgHostApi.setUp(
            flutterEngine.dartExecutor.binaryMessenger,
            BackgroundWorkerApiImpl(this)
        )
        
        // 注册网络连接检查 API
        ConnectivityApi.setUp(
            flutterEngine.dartExecutor.binaryMessenger,
            ConnectivityApiImpl(this) as ConnectivityApi
        )
        
        // 注册缩略图解码 API
        ThumbnailApi.setUp(
            flutterEngine.dartExecutor.binaryMessenger,
            ThumbnailsImpl(this)
        )
    }
    
    companion object {
        /// 注册插件到 Flutter Engine
        /// 用于在后台 Engine 中注册必要的插件
        fun registerPlugins(ctx: Context, engine: FlutterEngine) {
            // 注册后台工作器前台 API（供后台 Engine 使用）
            BackgroundWorkerFgHostApi.setUp(
                engine.dartExecutor.binaryMessenger,
                BackgroundWorkerApiImpl(ctx)
            )
            
            // 注册网络连接检查 API（供后台 Engine 使用）
            ConnectivityApi.setUp(
                engine.dartExecutor.binaryMessenger,
                ConnectivityApiImpl(ctx) as ConnectivityApi
            )
            
            // 注册缩略图解码 API（供后台 Engine 使用）
            ThumbnailApi.setUp(
                engine.dartExecutor.binaryMessenger,
                ThumbnailsImpl(ctx)
            )
        }
    }
}
