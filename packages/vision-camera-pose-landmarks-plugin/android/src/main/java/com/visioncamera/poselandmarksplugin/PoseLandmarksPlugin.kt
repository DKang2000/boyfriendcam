package com.visioncamera.poselandmarksplugin

import com.mrousavy.camera.frameprocessors.Frame
import com.mrousavy.camera.frameprocessors.FrameProcessorPlugin
import com.mrousavy.camera.frameprocessors.VisionCameraProxy

class PoseLandmarksPlugin(proxy: VisionCameraProxy, options: Map<String, Any>?) :
    FrameProcessorPlugin() {
    private val mediaPipeProcessor: MediaPipeFrameProcessor

    init {
        val modelPath = "pose_landmarker_full.task"
        val numPoses = options?.get("numPoses") as? Double
        val minPoseDetectionConfidence = options?.get("minPoseDetectionConfidence") as? Double
        val minPosePresenceConfidence = options?.get("minPosePresenceConfidence") as? Double
        val minTrackingConfidence = options?.get("minTrackingConfidence") as? Double

        mediaPipeProcessor = MediaPipeFrameProcessor(
            proxy.context,
            modelPath,
            numPoses?.toInt(),
            minTrackingConfidence?.toFloat(),
            minPosePresenceConfidence?.toFloat(),
            minPoseDetectionConfidence?.toFloat()
        )
    }

    override fun callback(frame: Frame, params: Map<String, Any>?): Any {
        return mediaPipeProcessor.process(frame)
    }

    companion object {
        const val NAME = "detectPoseLandmarks"
    }
}
