package com.amwolfstein.badalaty

import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.content.pm.Signature
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import androidx.core.content.pm.PackageInfoCompat
import io.flutter.plugin.common.MethodChannel
import java.io.File

class UpdateFileProvider : FileProvider()

internal class AndroidUpdates(private val activity: MainActivity) {
    private val packages get() = activity.packageManager
    private val packageName get() = activity.packageName

    @Suppress("DEPRECATION")
    private val signatureFlags = if (Build.VERSION.SDK_INT >= 28)
        PackageManager.GET_SIGNING_CERTIFICATES else PackageManager.GET_SIGNATURES

    @Suppress("DEPRECATION")
    private fun signers(info: PackageInfo): Set<Signature> =
        (if (Build.VERSION.SDK_INT >= 28) info.signingInfo?.apkContentsSigners
        else info.signatures).orEmpty().toSet()

    @Suppress("DEPRECATION")
    fun version(): Map<String, Any> {
        val installed = packages.getPackageInfo(packageName, 0)
        return mapOf(
            "version" to (installed.versionName ?: ""),
            "build" to PackageInfoCompat.getLongVersionCode(installed),
            "arm64" to Build.SUPPORTED_ABIS.contains("arm64-v8a"),
        )
    }

    @Suppress("DEPRECATION")
    fun install(expectedBuild: Long, result: MethodChannel.Result) {
        Thread {
            val apk = File(activity.cacheDir, "app-updates/badalaty.apk")
            val valid = runCatching {
                val installed = packages.getPackageInfo(packageName, signatureFlags)
                val update = packages.getPackageArchiveInfo(apk.absolutePath, signatureFlags)
                val certificates = signers(installed)
                update != null && update.packageName == packageName &&
                    PackageInfoCompat.getLongVersionCode(update) == expectedBuild &&
                    expectedBuild > PackageInfoCompat.getLongVersionCode(installed) &&
                    certificates.isNotEmpty() && certificates == signers(update)
            }.getOrDefault(false)
            activity.runOnUiThread {
                if (!valid || activity.isFinishing || activity.isDestroyed) {
                    result.error("invalid_update", null, null)
                    return@runOnUiThread
                }
                runCatching {
                    if (Build.VERSION.SDK_INT >= 26 && !packages.canRequestPackageInstalls()) {
                        activity.startActivity(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                            Uri.parse("package:$packageName")))
                        "permission"
                    } else {
                        val data = FileProvider.getUriForFile(activity, "$packageName.updates", apk)
                        activity.startActivity(Intent(Intent.ACTION_VIEW)
                            .setDataAndType(data, "application/vnd.android.package-archive")
                            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION))
                        "installer"
                    }
                }.onSuccess(result::success).onFailure { result.error("install_failed", null, null) }
            }
        }.start()
    }
}
