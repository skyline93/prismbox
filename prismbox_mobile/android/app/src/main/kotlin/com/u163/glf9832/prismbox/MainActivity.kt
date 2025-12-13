package com.u163.glf9832.prismbox

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import app.prismbox.HttpSSLOptionsPlugin
import app.prismbox.StoragePlugin
import app.prismbox.background.BackgroundWorkerApiImpl
import app.prismbox.background.BackgroundWorkerFgHostApi

class MainActivity : FlutterActivity() {
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
        }
    }
}
