package com.u163.glf9832.prismbox

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import app.prismbox.HttpSSLOptionsPlugin

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // 注册HttpSSLOptionsPlugin
        flutterEngine.plugins.add(HttpSSLOptionsPlugin())
    }
}
