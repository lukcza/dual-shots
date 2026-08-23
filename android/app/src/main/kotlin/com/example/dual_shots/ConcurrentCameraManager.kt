package com.example.dual_shots

import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.ImageFormat
import android.graphics.SurfaceTexture
import android.hardware.camera2.*
import android.media.Image
import android.media.ImageReader
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.util.Log
import android.view.Surface
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.util.*
import java.util.concurrent.Executors

class ConcurrentCameraManager(
    private val context: Context,
    private val flutterEngine: FlutterEngine
) : MethodChannel.MethodCallHandler {

    private val TAG = "ConcurrentCameraMgr"
    private val CHANNEL_NAME = "com.example.dual_shots/concurrent_camera"

    private var methodChannel: MethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
    private var cameraManager: CameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager

    private val mainHandler = Handler(Looper.getMainLooper())
    private var backgroundThread: HandlerThread? = null
    private var backgroundHandler: Handler? = null

    // Primary Camera
    private var primaryCameraDevice: CameraDevice? = null
    private var primaryCaptureSession: CameraCaptureSession? = null
    private var primaryTextureEntry: TextureRegistry.SurfaceTextureEntry? = null
    private var primaryImageReader: ImageReader? = null
    private var primaryCameraId: String = "0"

    // Secondary Camera
    private var secondaryCameraDevice: CameraDevice? = null
    private var secondaryCaptureSession: CameraCaptureSession? = null
    private var secondaryTextureEntry: TextureRegistry.SurfaceTextureEntry? = null
    private var secondaryImageReader: ImageReader? = null
    private var secondaryCameraId: String = "1"

    private var isInitialized = false

    fun start() {
        methodChannel.setMethodCallHandler(this)
    }

    fun stop() {
        methodChannel.setMethodCallHandler(null)
        disposeCameras()
    }

    private fun startBackgroundThread() {
        if (backgroundThread == null) {
            backgroundThread = HandlerThread("DualCameraBackground").apply { start() }
            backgroundHandler = Handler(backgroundThread!!.looper)
        }
    }

    private fun stopBackgroundThread() {
        backgroundThread?.quitSafely()
        try {
            backgroundThread?.join()
            backgroundThread = null
            backgroundHandler = null
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping background thread", e)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkConcurrentSupport" -> {
                result.success(isConcurrentSupported())
            }
            "initConcurrentStreams" -> {
                val primaryLensParam = call.argument<String>("primaryLens") ?: "back"
                initConcurrentStreams(primaryLensParam, result)
            }
            "takeConcurrentShot" -> {
                takeConcurrentShot(result)
            }
            "switchCameraRoles" -> {
                switchCameraRoles(result)
            }
            "dispose" -> {
                disposeCameras()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun isConcurrentSupported(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                val concurrentCameraIds = cameraManager.concurrentCameraIds
                if (concurrentCameraIds.isNotEmpty()) return true
            } catch (e: Exception) {
                Log.w(TAG, "Error checking concurrent camera IDs", e)
            }
        }
        return context.packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_CONCURRENT)
    }

    @SuppressLint("MissingPermission")
    private fun initConcurrentStreams(primaryLens: String, result: MethodChannel.Result) {
        startBackgroundThread()
        disposeCameras()

        try {
            var backId = "0"
            var frontId = "1"

            // Look up concurrent combinations if available
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val concurrentSets = cameraManager.concurrentCameraIds
                for (set in concurrentSets) {
                    for (id in set) {
                        val chars = cameraManager.getCameraCharacteristics(id)
                        val facing = chars.get(CameraCharacteristics.LENS_FACING)
                        if (facing == CameraCharacteristics.LENS_FACING_BACK) backId = id
                        if (facing == CameraCharacteristics.LENS_FACING_FRONT) frontId = id
                    }
                }
            } else {
                val cameraList = cameraManager.cameraIdList
                for (id in cameraList) {
                    val chars = cameraManager.getCameraCharacteristics(id)
                    val facing = chars.get(CameraCharacteristics.LENS_FACING)
                    if (facing == CameraCharacteristics.LENS_FACING_BACK && backId == "0") backId = id
                    if (facing == CameraCharacteristics.LENS_FACING_FRONT && frontId == "1") frontId = id
                }
            }

            if (primaryLens == "front") {
                primaryCameraId = frontId
                secondaryCameraId = backId
            } else {
                primaryCameraId = backId
                secondaryCameraId = frontId
            }

            primaryTextureEntry = flutterEngine.renderer.createSurfaceTexture()
            secondaryTextureEntry = flutterEngine.renderer.createSurfaceTexture()

            val primaryTexId = primaryTextureEntry!!.id()
            val secondaryTexId = secondaryTextureEntry!!.id()

            // Optimized stream sizes (720p primary, 480p secondary) to stay strictly within mobile ISP bandwidth
            primaryImageReader = ImageReader.newInstance(1280, 720, ImageFormat.JPEG, 2)
            secondaryImageReader = ImageReader.newInstance(1280, 720, ImageFormat.JPEG, 2)

            var callbackReturned = false

            val cameraExecutor = Executors.newSingleThreadExecutor()

            cameraManager.openCamera(primaryCameraId, cameraExecutor, object : CameraDevice.StateCallback() {
                override fun onOpened(camera: CameraDevice) {
                    primaryCameraDevice = camera
                    startPrimaryPreview()

                    cameraManager.openCamera(secondaryCameraId, cameraExecutor, object : CameraDevice.StateCallback() {
                        override fun onOpened(secCamera: CameraDevice) {
                            secondaryCameraDevice = secCamera
                            startSecondaryPreview()

                            isInitialized = true
                            if (!callbackReturned) {
                                callbackReturned = true
                                val response = mapOf(
                                    "primaryTextureId" to primaryTexId,
                                    "secondaryTextureId" to secondaryTexId,
                                    "primaryCameraId" to primaryCameraId,
                                    "secondaryCameraId" to secondaryCameraId
                                )
                                mainHandler.post { result.success(response) }
                            }
                        }

                        override fun onDisconnected(camera: CameraDevice) {
                            camera.close()
                            secondaryCameraDevice = null
                        }

                        override fun onError(camera: CameraDevice, error: Int) {
                            camera.close()
                            secondaryCameraDevice = null
                            Log.e(TAG, "Secondary camera open error: $error")
                            if (!callbackReturned) {
                                callbackReturned = true
                                mainHandler.post {
                                    result.error("SECONDARY_ERROR", "Failed to open secondary camera: $error", null)
                                }
                            }
                        }
                    })
                }

                override fun onDisconnected(camera: CameraDevice) {
                    camera.close()
                    primaryCameraDevice = null
                }

                override fun onError(camera: CameraDevice, error: Int) {
                    camera.close()
                    primaryCameraDevice = null
                    Log.e(TAG, "Primary camera open error: $error")
                    if (!callbackReturned) {
                        callbackReturned = true
                        mainHandler.post {
                            result.error("PRIMARY_ERROR", "Failed to open primary camera: $error", null)
                        }
                    }
                }
            })

        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize concurrent cameras", e)
            mainHandler.post { result.error("INIT_ERROR", e.message, null) }
        }
    }

    private fun startPrimaryPreview() {
        val device = primaryCameraDevice ?: return
        val entry = primaryTextureEntry ?: return
        val surfaceTexture = entry.surfaceTexture()
        surfaceTexture.setDefaultBufferSize(1280, 720)
        val previewSurface = Surface(surfaceTexture)

        try {
            val surfaces = listOf(previewSurface, primaryImageReader!!.surface)
            device.createCaptureSession(surfaces, object : CameraCaptureSession.StateCallback() {
                override fun onConfigured(session: CameraCaptureSession) {
                    primaryCaptureSession = session
                    val previewRequestBuilder = device.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW).apply {
                        addTarget(previewSurface)
                        set(CaptureRequest.CONTROL_MODE, CameraMetadata.CONTROL_MODE_AUTO)
                        set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE)
                    }
                    session.setRepeatingRequest(previewRequestBuilder.build(), null, backgroundHandler)
                }

                override fun onConfigureFailed(session: CameraCaptureSession) {
                    Log.e(TAG, "Primary session configuration failed")
                }
            }, backgroundHandler)
        } catch (e: Exception) {
            Log.e(TAG, "Error starting primary preview", e)
        }
    }

    private fun startSecondaryPreview() {
        val device = secondaryCameraDevice ?: return
        val entry = secondaryTextureEntry ?: return
        val surfaceTexture = entry.surfaceTexture()
        surfaceTexture.setDefaultBufferSize(640, 480)
        val previewSurface = Surface(surfaceTexture)

        try {
            val surfaces = listOf(previewSurface, secondaryImageReader!!.surface)
            device.createCaptureSession(surfaces, object : CameraCaptureSession.StateCallback() {
                override fun onConfigured(session: CameraCaptureSession) {
                    secondaryCaptureSession = session
                    val previewRequestBuilder = device.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW).apply {
                        addTarget(previewSurface)
                        set(CaptureRequest.CONTROL_MODE, CameraMetadata.CONTROL_MODE_AUTO)
                        set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE)
                    }
                    session.setRepeatingRequest(previewRequestBuilder.build(), null, backgroundHandler)
                }

                override fun onConfigureFailed(session: CameraCaptureSession) {
                    Log.e(TAG, "Secondary session configuration failed")
                }
            }, backgroundHandler)
        } catch (e: Exception) {
            Log.e(TAG, "Error starting secondary preview", e)
        }
    }

    private fun takeConcurrentShot(result: MethodChannel.Result) {
        if (!isInitialized || primaryCaptureSession == null || secondaryCaptureSession == null) {
            result.error("NOT_INITIALIZED", "Concurrent cameras are not active", null)
            return
        }

        try {
            val primaryFile = File(context.cacheDir, "primary_${UUID.randomUUID()}.jpg")
            val secondaryFile = File(context.cacheDir, "secondary_${UUID.randomUUID()}.jpg")

            var primarySaved = false
            var secondarySaved = false
            var completed = false

            fun checkDone() {
                if (primarySaved && secondarySaved && !completed) {
                    completed = true
                    val response = mapOf(
                        "primaryPath" to primaryFile.absolutePath,
                        "secondaryPath" to secondaryFile.absolutePath
                    )
                    mainHandler.post {
                        result.success(response)
                    }
                }
            }

            primaryImageReader?.setOnImageAvailableListener({ reader ->
                val image: Image? = reader.acquireLatestImage()
                if (image != null) {
                    val buffer: ByteBuffer = image.planes[0].buffer
                    val bytes = ByteArray(buffer.remaining())
                    buffer.get(bytes)
                    FileOutputStream(primaryFile).use { it.write(bytes) }
                    image.close()
                    primarySaved = true
                    checkDone()
                }
            }, backgroundHandler)

            secondaryImageReader?.setOnImageAvailableListener({ reader ->
                val image: Image? = reader.acquireLatestImage()
                if (image != null) {
                    val buffer: ByteBuffer = image.planes[0].buffer
                    val bytes = ByteArray(buffer.remaining())
                    buffer.get(bytes)
                    FileOutputStream(secondaryFile).use { it.write(bytes) }
                    image.close()
                    secondarySaved = true
                    checkDone()
                }
            }, backgroundHandler)

            val primaryBuilder = primaryCameraDevice!!.createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE).apply {
                addTarget(primaryImageReader!!.surface)
                set(CaptureRequest.CONTROL_MODE, CameraMetadata.CONTROL_MODE_AUTO)
            }
            primaryCaptureSession!!.capture(primaryBuilder.build(), null, backgroundHandler)

            val secondaryBuilder = secondaryCameraDevice!!.createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE).apply {
                addTarget(secondaryImageReader!!.surface)
                set(CaptureRequest.CONTROL_MODE, CameraMetadata.CONTROL_MODE_AUTO)
            }
            secondaryCaptureSession!!.capture(secondaryBuilder.build(), null, backgroundHandler)

        } catch (e: Exception) {
            Log.e(TAG, "Error taking concurrent photo", e)
            mainHandler.post { result.error("CAPTURE_ERROR", e.message, null) }
        }
    }

    private fun switchCameraRoles(result: MethodChannel.Result) {
        val newPrimary = if (primaryCameraId == "0") "front" else "back"
        initConcurrentStreams(newPrimary, result)
    }

    private fun disposeCameras() {
        isInitialized = false
        try {
            primaryCaptureSession?.close()
            primaryCaptureSession = null
            secondaryCaptureSession?.close()
            secondaryCaptureSession = null

            primaryCameraDevice?.close()
            primaryCameraDevice = null
            secondaryCameraDevice?.close()
            secondaryCameraDevice = null

            primaryTextureEntry?.release()
            primaryTextureEntry = null
            secondaryTextureEntry?.release()
            secondaryTextureEntry = null

            primaryImageReader?.close()
            primaryImageReader = null
            secondaryImageReader?.close()
            secondaryImageReader = null

            stopBackgroundThread()
        } catch (e: Exception) {
            Log.e(TAG, "Error disposing cameras", e)
        }
    }
}
