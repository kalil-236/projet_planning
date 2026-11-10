package com.kalil236.assistant_planning

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Reçoit les plannings ouverts avec F.R.I.D.A.Y ou partagés vers elle, et les
/// transmet à l'écran Importer (canal `friday/shared_plan`).
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var pending: Map<String, String>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pending = readShared(intent)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                if (call.method == "initial") {
                    result.success(pending)
                    pending = null
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        readShared(intent)?.let { channel?.invokeMethod("shared", it) }
    }

    private fun readShared(intent: Intent?): Map<String, String>? {
        if (intent == null) return null
        return try {
            when (intent.action) {
                Intent.ACTION_SEND -> {
                    val stream = streamExtra(intent)
                    if (stream != null) {
                        readUri(stream)
                    } else {
                        intent.getStringExtra(Intent.EXTRA_TEXT)?.let {
                            mapOf("name" to "Texte partagé", "text" to it)
                        }
                    }
                }
                Intent.ACTION_VIEW -> intent.data?.let { readUri(it) }
                else -> null
            }
        } catch (error: Exception) {
            mapOf("name" to "Fichier partagé", "error" to (error.message ?: "lecture impossible"))
        }
    }

    @Suppress("DEPRECATION")
    private fun streamExtra(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }

    private fun readUri(uri: Uri): Map<String, String> {
        val name = displayName(uri) ?: "Fichier partagé"
        val bytes = contentResolver.openInputStream(uri)?.use { input ->
            val buffer = ByteArray(MAX_BYTES + 1)
            var total = 0
            while (total < buffer.size) {
                val read = input.read(buffer, total, buffer.size - total)
                if (read < 0) break
                total += read
            }
            buffer.copyOf(total)
        } ?: return mapOf("name" to name, "error" to "fichier introuvable")
        if (bytes.size > MAX_BYTES) {
            return mapOf("name" to name, "error" to "fichier trop volumineux (plus de 1 Mo)")
        }
        return mapOf("name" to name, "text" to bytes.toString(Charsets.UTF_8))
    }

    private fun displayName(uri: Uri): String? {
        if (uri.scheme != "content") return uri.lastPathSegment
        return contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor -> if (cursor.moveToFirst()) cursor.getString(0) else null }
    }

    companion object {
        private const val CHANNEL = "friday/shared_plan"
        private const val MAX_BYTES = 1024 * 1024
    }
}
