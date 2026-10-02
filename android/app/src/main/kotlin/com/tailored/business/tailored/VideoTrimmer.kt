package com.tailored.business.tailored

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.media.MediaMuxer
import java.nio.ByteBuffer

/**
 * Lossless video trim via MediaExtractor + MediaMuxer.
 *
 * Scoped video (Phase 8 / proposal §4): reference clips are trimmed short on the
 * device before upload — this copies the sample stream inside [startMs, endMs]
 * into a fresh MP4 WITHOUT re-encoding (no ffmpeg, no giant native binaries).
 * The backend's 20MB size cap remains the authoritative limit; this just keeps
 * clips within the ~10s the trim screen enforces.
 *
 * Because a lossless copy must begin on a keyframe, the output can include a few
 * frames before the requested start (the preceding sync sample). That's an
 * accepted trade for not re-encoding — good enough for a short reference clip.
 */
object VideoTrimmer {

    fun trim(srcPath: String, startMs: Long, endMs: Long, dstPath: String) {
        val extractor = MediaExtractor()
        var muxer: MediaMuxer? = null
        try {
            extractor.setDataSource(srcPath)
            val trackCount = extractor.trackCount

            muxer = MediaMuxer(dstPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

            // Select the audio + video tracks and map each source track index to
            // its muxer track index.
            val indexMap = HashMap<Int, Int>(trackCount)
            var maxInputSize = 0
            for (i in 0 until trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: continue
                if (mime.startsWith("video/") || mime.startsWith("audio/")) {
                    extractor.selectTrack(i)
                    indexMap[i] = muxer.addTrack(format)
                    if (format.containsKey(MediaFormat.KEY_MAX_INPUT_SIZE)) {
                        maxInputSize =
                            maxOf(maxInputSize, format.getInteger(MediaFormat.KEY_MAX_INPUT_SIZE))
                    }
                }
            }
            if (indexMap.isEmpty()) {
                throw IllegalStateException("No audio/video track found in source")
            }
            if (maxInputSize <= 0) maxInputSize = 2 * 1024 * 1024

            // Keep the display rotation so a portrait phone clip isn't sideways.
            val retriever = MediaMetadataRetriever()
            try {
                retriever.setDataSource(srcPath)
                retriever
                    .extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)
                    ?.toIntOrNull()
                    ?.let { muxer.setOrientationHint(it) }
            } finally {
                retriever.release()
            }

            val startUs = startMs * 1000
            val endUs = endMs * 1000

            // Seek every selected track to the sync sample at or before start.
            extractor.seekTo(startUs, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)

            muxer.start()

            val buffer = ByteBuffer.allocate(maxInputSize)
            val bufferInfo = MediaCodec.BufferInfo()
            var baseTimeUs = -1L

            while (true) {
                val sampleTime = extractor.sampleTime
                if (sampleTime < 0) break          // end of stream
                if (sampleTime > endUs) break      // past the selection

                val trackIndex = extractor.sampleTrackIndex
                val dstIndex = indexMap[trackIndex]
                if (dstIndex == null) {
                    extractor.advance()
                    continue
                }

                val size = extractor.readSampleData(buffer, 0)
                if (size < 0) break

                // Shift output timestamps toward zero so the clip starts at ~0;
                // one shared base keeps audio/video in sync.
                if (baseTimeUs < 0) baseTimeUs = sampleTime

                bufferInfo.offset = 0
                bufferInfo.size = size
                bufferInfo.presentationTimeUs = (sampleTime - baseTimeUs).coerceAtLeast(0)
                bufferInfo.flags =
                    if (extractor.sampleFlags and MediaExtractor.SAMPLE_FLAG_SYNC != 0) {
                        MediaCodec.BUFFER_FLAG_KEY_FRAME
                    } else {
                        0
                    }

                muxer.writeSampleData(dstIndex, buffer, bufferInfo)
                extractor.advance()
            }
        } finally {
            try {
                muxer?.stop()
            } catch (_: Exception) {
                // stop() throws if no data was written — swallow so release runs.
            }
            try {
                muxer?.release()
            } catch (_: Exception) {
            }
            extractor.release()
        }
    }
}
