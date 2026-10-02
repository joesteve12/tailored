package com.tailored.business.tailored

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {

    // Scoped video (Phase 8): the Flutter trim screen hands us a source clip and
    // a [start, end] window; we losslessly remux it (see VideoTrimmer) and return
    // the trimmed file's path. No ffmpeg — MediaMuxer only.
    private val videoTrimChannel = "tailored/video_trim"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, videoTrimChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "trim" -> {
                        val srcPath = call.argument<String>("srcPath")
                        val startMs = call.argument<Number>("startMs")?.toLong()
                        val endMs = call.argument<Number>("endMs")?.toLong()
                        if (srcPath == null || startMs == null || endMs == null) {
                            result.error(
                                "bad_args",
                                "srcPath, startMs and endMs are required",
                                null,
                            )
                            return@setMethodCallHandler
                        }

                        val dstPath =
                            File(cacheDir, "trim_${System.currentTimeMillis()}.mp4").absolutePath

                        // Trimming touches disk — never on the main thread. Post the
                        // result back on the main looper, as MethodChannel requires.
                        thread {
                            try {
                                VideoTrimmer.trim(srcPath, startMs, endMs, dstPath)
                                Handler(Looper.getMainLooper()).post { result.success(dstPath) }
                            } catch (e: Exception) {
                                Handler(Looper.getMainLooper()).post {
                                    result.error("trim_failed", e.message, null)
                                }
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
