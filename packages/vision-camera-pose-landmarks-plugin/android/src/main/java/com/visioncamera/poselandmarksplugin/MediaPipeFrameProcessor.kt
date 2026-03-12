package com.visioncamera.poselandmarksplugin

import android.content.Context
import com.google.mediapipe.framework.image.MediaImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import com.mrousavy.camera.frameprocessors.Frame

class MediaPipeFrameProcessor(
    private val context: Context,
    modelPath: String?,
    numPoses: Int?,
    minTrackingConfidence: Float?,
    minPosePresenceConfidence: Float?,
    minPoseDetectionConfidence: Float?
) {
    private val landmarkNames = listOf(
        "nose", "leftEyeInner", "leftEye", "leftEyeOuter",
        "rightEyeInner", "rightEye", "rightEyeOuter", "leftEar",
        "rightEar", "leftMouth", "rightMouth", "leftShoulder",
        "rightShoulder", "leftElbow", "rightElbow", "leftWrist",
        "rightWrist", "leftPinky", "rightPinky", "leftIndex",
        "rightIndex", "leftThumb", "rightThumb", "leftHip",
        "rightHip", "leftKnee", "rightKnee", "leftAnkle",
        "rightAnkle", "leftHeel", "rightHeel", "leftFootIndex",
        "rightFootIndex"
    )
    private val poseLandmarkerOptions: PoseLandmarker.PoseLandmarkerOptions
    private val poseLandmarker: PoseLandmarker? by lazy {
        PoseLandmarker.createFromOptions(context, poseLandmarkerOptions)
    }

    init {
        val optionsBuilder = PoseLandmarker.PoseLandmarkerOptions.builder()
            .setRunningMode(RunningMode.VIDEO)

        modelPath?.let {
            val baseOptions = BaseOptions.builder()
                .setModelAssetPath(it).build()

            optionsBuilder.setBaseOptions(baseOptions)
        }
        numPoses?.let { optionsBuilder.setNumPoses(it) }
        minPoseDetectionConfidence?.let { optionsBuilder.setMinPoseDetectionConfidence(it) }
        minPosePresenceConfidence?.let { optionsBuilder.setMinPosePresenceConfidence(it) }
        minTrackingConfidence?.let { optionsBuilder.setMinTrackingConfidence(it) }

        poseLandmarkerOptions = optionsBuilder.build()
    }

    fun process(frame: Frame): List<Map<String, Map<String, Double>>> {
        val poseLandmarker = poseLandmarker ?: return emptyList()

        try {
            val mpImage = MediaImageBuilder(frame.image).build()
            val result = poseLandmarker.detectForVideo(mpImage, frame.timestamp)

            return result?.landmarks()?.map { pose ->
                pose.mapIndexed { index, landmark ->
                    landmarkNames[index] to mapOf(
                        "x" to landmark.x().toDouble(),
                        "y" to landmark.y().toDouble(),
                        "z" to landmark.z().toDouble(),
                        "visibility" to (landmark.visibility().orElse(0.0f).toDouble()),
                        "presence" to (landmark.presence().orElse(0.0f).toDouble())
                    )
                }.toMap()
            } ?: emptyList()
        } catch (error: Exception) {
            return emptyList()
        }
    }
}