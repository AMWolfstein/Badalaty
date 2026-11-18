package com.amwolfstein.badalaty

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val updates = AndroidUpdates(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "badalaty/updates")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "version" -> result.success(updates.version())
                    "install" -> {
                        val build = (call.arguments as? Number)?.toLong()
                        if (build == null) result.error("invalid_update", null, null)
                        else updates.install(build, result)
                    }
                    else -> result.notImplemented()
                }
            }
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "badalaty/platform")
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "publish" -> {
                    val content = call.arguments as String
                    WidgetData.preferences(this).edit().putString("display", content).apply()
                    WidgetData.refresh(this)
                    WidgetData.schedule(this)
                    result.success(null)
                }
                "initialRoute" -> result.success(takeRoute(intent))
                "permission" -> {
                    if (Build.VERSION.SDK_INT >= 33 &&
                        checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
                    ) requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 10)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        takeRoute(intent)?.let { channel?.invokeMethod("route", it) }
    }

    private fun takeRoute(intent: Intent?): String? {
        val route = intent?.getStringExtra("route")
        intent?.removeExtra("route")
        return route
    }
}
