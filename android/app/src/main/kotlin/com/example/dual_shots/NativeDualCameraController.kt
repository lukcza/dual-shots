package com.example.dual_shots

import android.annotation.SuppressLint
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.ImageFormat
import android.graphics.SurfaceTexture
import android.hardware.camera2.*
import android.media.Image
import android.media.ImageReader
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.provider.MediaStore
import android.util.Log
import android.view.Surface
import android.view.TextureView
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.util.*
import java.util.concurrent.Executors

object NativeDualCameraController : MethodChannel.MethodCallHandler {

    private const val TAG = "NativeDualCam"
    private val mainHandler = Handler(Looper.getMainLooper())

    private var appContext: Context? = null
    private var cameraManager: CameraManager? = null

    private var backgroundThread: HandlerThread? = null
    private var backgroundHandler: Handler? = null
    private val cameraExecutor = Executors.newFixedThreadPool(2)

    var primaryTextureView: TextureView? = null
    var secondaryTextureView: TextureView? = null

    private var primaryCameraDevice: CameraDevice? = null
    private var primarySession: CameraCaptureSession? = null
    private var primaryImageReader: ImageReader? = null
    private var primaryCameraId = "0"

    private var secondaryCameraDevice: CameraDevice? = null
    private var secondarySession: CameraCaptureSession? = null
    private var secondaryImageReader: ImageReader? = null
    private var secondaryCameraId = "1"

    private var currentFlashMode = "off"
    private var isPrimaryAttached = false
    private var isSecondaryAttached = false
    var isInitialized = false

    fun init(context: Context, messenger: io.flutter.plugin.common.BinaryMessenger) {
        appContext = context.applicationContext
        cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        MethodChannel(messenger, "com.example.dual_shots/native_dual_camera").setMethodCallHandler(this)
    }

    private fun startBackgroundThread() {
        if (backgroundThread == null) {
            backgroundThread = HandlerThread("NativeDualCameraBackground").apply { start() }
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

    fun attachPrimarySurface(textureView: TextureView) {
        primaryTextureView = textureView
        isPrimaryAttached = true
        checkAndStartStreams()
    }

    fun attachSecondarySurface(textureView: TextureView) {
        secondaryTextureView = textureView
        isSecondaryAttached = true
        checkAndStartStreams()
    }

    fun detachPrimary() {
        isPrimaryAttached = false
        primaryTextureView = null
        closePrimary()
    }

    fun detachSecondary() {
        isSecondaryAttached = false
        secondaryTextureView = null
        closeSecondary()
    }

    private fun checkAndStartStreams() {
        if (isPrimaryAttached && isSecondaryAttached) {
            startBackgroundThread()
            detectCameraIds()
            openBothCameras()
        }
    }

    private fun detectCameraIds() {
        val manager = cameraManager ?: return
        try {
            var backId = "0"
            var frontId = "1"

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val concurrentSets = manager.concurrentCameraIds
                for (set in concurrentSets) {
                    for (id in set) {
                        val chars = manager.getCameraCharacteristics(id)
                        val facing = chars.get(CameraCharacteristics.LENS_FACING)
                        if (facing == CameraCharacteristics.LENS_FACING_BACK) backId = id
                        if (facing == CameraCharacteristics.LENS_FACING_FRONT) frontId = id
                    }
                }
            } else {
                for (id in manager.cameraIdList) {
                    val chars = manager.getCameraCharacteristics(id)
                    val facing = chars.get(CameraCharacteristics.LENS_FACING)
                    if (facing == CameraCharacteristics.LENS_FACING_BACK && backId == "0") backId = id
                    if (facing == CameraCharacteristics.LENS_FACING_FRONT && frontId == "1") frontId = id
                }
            }

            primaryCameraId = backId
            secondaryCameraId = frontId
        } catch (e: Exception) {
            Log.e(TAG, "Error detecting camera IDs", e)
        }
    }

    @SuppressLint("MissingPermission")
    private fun openBothCameras() {
        val manager = cameraManager ?: return

        // 1. Open Primary Camera
        try {
            manager.openCamera(primaryCameraId, cameraExecutor, object : CameraDevice.StateCallback() {
                override fun onOpened(camera: CameraDevice) {
                    primaryCameraDevice = camera
                    startPrimaryPreview()

                    // 2. Open Secondary Camera concurrently
                    try {
                        manager.openCamera(secondaryCameraId, cameraExecutor, object : CameraDevice.StateCallback() {
                            override fun onOpened(secCamera: CameraDevice) {
                                secondaryCameraDevice = secCamera
                                startSecondaryPreview()
                                isInitialized = true
                                Log.i(TAG, "Both cameras streaming concurrently!")
                            }

                            override fun onDisconnected(camera: CameraDevice) {
                                camera.close()
                                secondaryCameraDevice = null
                            }

                            override fun onError(camera: CameraDevice, error: Int) {
                                camera.close()
                                secondaryCameraDevice = null
                                Log.w(TAG, "Secondary camera open error: $error")
                            }
                        })
                    } catch (e: Exception) {
                        Log.e(TAG, "Error opening secondary camera", e)
                    }
                }

                override fun onDisconnected(camera: CameraDevice) {
                    camera.close()
                    primaryCameraDevice = null
                }

                override fun onError(camera: CameraDevice, error: Int) {
                    camera.close()
                    primaryCameraDevice = null
                    Log.e(TAG, "Primary camera open error: $error")
                }
            })
        } catch (e: Exception) {
            Log.e(TAG, "Error opening primary camera", e)
        }
    }

    private fun startPrimaryPreview() {
        val device = primaryCameraDevice ?: return
        val textureView = primaryTextureView ?: return
        val surfaceTexture = textureView.surfaceTexture ?: return

        surfaceTexture.setDefaultBufferSize(1280, 720)
        val previewSurface = Surface(surfaceTexture)

        try {
            primaryImageReader = ImageReader.newInstance(1280, 720, ImageFormat.JPEG, 2)
            val surfaces = listOf(previewSurface, primaryImageReader!!.surface)

            device.createCaptureSession(surfaces, object : CameraCaptureSession.StateCallback() {
                override fun onConfigured(session: CameraCaptureSession) {
                    primarySession = session
                    applyPrimaryPreviewRequest()
                }

                override fun onConfigureFailed(session: CameraCaptureSession) {
                    Log.e(TAG, "Primary capture session config failed")
                }
            }, backgroundHandler)
        } catch (e: Exception) {
            Log.e(TAG, "Error configuring primary preview", e)
        }
    }

    private fun applyPrimaryPreviewRequest() {
        val device = primaryCameraDevice ?: return
        val session = primarySession ?: return
        val textureView = primaryTextureView ?: return
        val surfaceTexture = textureView.surfaceTexture ?: return
        val previewSurface = Surface(surfaceTexture)

        try {
            val req = device.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW).apply {
                addTarget(previewSurface)
                when (currentFlashMode) {
                    "torch" -> {
                        set(CaptureRequest.CONTROL_AE_MODE, CaptureRequest.CONTROL_AE_MODE_ON)
                        set(CaptureRequest.FLASH_MODE, CaptureRequest.FLASH_MODE_TORCH)
                    }
                    "on" -> {
                        set(CaptureRequest.CONTROL_AE_MODE, CaptureRequest.CONTROL_AE_MODE_ON_ALWAYS_FLASH)
                        set(CaptureRequest.FLASH_MODE, CaptureRequest.FLASH_MODE_SINGLE)
                    }
                    "auto" -> {
                        set(CaptureRequest.CONTROL_AE_MODE, CaptureRequest.CONTROL_AE_MODE_ON_AUTO_FLASH)
                    }
                    else -> {
                        set(CaptureRequest.CONTROL_AE_MODE, CaptureRequest.CONTROL_AE_MODE_ON)
                        set(CaptureRequest.FLASH_MODE, CaptureRequest.FLASH_MODE_OFF)
                    }
                }
                set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE)
            }
            session.setRepeatingRequest(req.build(), null, backgroundHandler)
        } catch (e: Exception) {
            Log.e(TAG, "Error applying primary request", e)
        }
    }

    private fun startSecondaryPreview() {
        val device = secondaryCameraDevice ?: return
        val textureView = secondaryTextureView ?: return
        val surfaceTexture = textureView.surfaceTexture ?: return

        surfaceTexture.setDefaultBufferSize(640, 480)
        val previewSurface = Surface(surfaceTexture)

        try {
            secondaryImageReader = ImageReader.newInstance(640, 480, ImageFormat.JPEG, 2)
            val surfaces = listOf(previewSurface, secondaryImageReader!!.surface)

            device.createCaptureSession(surfaces, object : CameraCaptureSession.StateCallback() {
                override fun onConfigured(session: CameraCaptureSession) {
                    secondarySession = session
                    val req = device.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW).apply {
                        addTarget(previewSurface)
                        set(CaptureRequest.CONTROL_MODE, CameraMetadata.CONTROL_MODE_AUTO)
                        set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE)
                    }
                    session.setRepeatingRequest(req.build(), null, backgroundHandler)
                }

                override fun onConfigureFailed(session: CameraCaptureSession) {
                    Log.e(TAG, "Secondary capture session config failed")
                }
            }, backgroundHandler)
        } catch (e: Exception) {
            Log.e(TAG, "Error configuring secondary preview", e)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "takeDualShot" -> {
                takeDualSnapshot(result)
            }
            "setFlashMode" -> {
                val mode = call.argument<String>("mode") ?: "off"
                currentFlashMode = mode
                applyPrimaryPreviewRequest()
                result.success(true)
            }
            "openGallery" -> {
                openGallery(result)
            }
            "saveToGallery" -> {
                val path = call.argument<String>("path")
                if (path != null) {
                    saveToGallery(path, result)
                } else {
                    result.error("INVALID_ARGS", "Path argument missing", null)
                }
            }
            "switchCameraRoles" -> {
                switchRoles(result)
            }
            "dispose" -> {
                disposeAll()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun openGallery(result: MethodChannel.Result) {
        val context = appContext ?: run {
            result.error("NO_CONTEXT", "App context missing", null)
            return
        }

        try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, "image/*")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
            mainHandler.post { result.success(true) }
        } catch (e: Exception) {
            try {
                val intent = Intent(Intent.ACTION_MAIN).apply {
                    addCategory(Intent.CATEGORY_APP_GALLERY)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(intent)
                mainHandler.post { result.success(true) }
            } catch (e2: Exception) {
                Log.e(TAG, "Could not open gallery intent", e2)
                mainHandler.post { result.error("OPEN_GALLERY_FAILED", e2.message, null) }
            }
        }
    }

    private fun takeDualSnapshot(result: MethodChannel.Result) {
        val context = appContext ?: run {
            result.error("NO_CONTEXT", "App context not available", null)
            return
        }

        try {
            val primaryFile = File(context.cacheDir, "primary_${UUID.randomUUID()}.jpg")
            val secondaryFile = File(context.cacheDir, "secondary_${UUID.randomUUID()}.jpg")

            val primaryBmp = primaryTextureView?.bitmap
            val secondaryBmp = secondaryTextureView?.bitmap

            if (primaryBmp != null) {
                FileOutputStream(primaryFile).use { out ->
                    primaryBmp.compress(Bitmap.CompressFormat.JPEG, 92, out)
                }
            }

            if (secondaryBmp != null) {
                FileOutputStream(secondaryFile).use { out ->
                    secondaryBmp.compress(Bitmap.CompressFormat.JPEG, 92, out)
                }
            }

            val response = mapOf(
                "primaryPath" to primaryFile.absolutePath,
                "secondaryPath" to secondaryFile.absolutePath
            )

            mainHandler.post { result.success(response) }
        } catch (e: Exception) {
            Log.e(TAG, "Error capturing dual snapshot", e)
            mainHandler.post { result.error("CAPTURE_ERROR", e.message, null) }
        }
    }

    private fun saveToGallery(path: String, result: MethodChannel.Result) {
        val context = appContext ?: run {
            result.error("NO_CONTEXT", "Context missing", null)
            return
        }

        try {
            val file = File(path)
            if (!file.exists()) {
                result.error("FILE_NOT_FOUND", "File does not exist: $path", null)
                return
            }

            val filename = "DualShot_${System.currentTimeMillis()}.jpg"

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val values = ContentValues().apply {
                    put(MediaStore.Images.Media.DISPLAY_NAME, filename)
                    put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                    put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/DualShots")
                    put(MediaStore.Images.Media.IS_PENDING, 1)
                }

                val uri = context.contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                if (uri != null) {
                    context.contentResolver.openOutputStream(uri)?.use { out ->
                        FileInputStream(file).use { input ->
                            input.copyTo(out)
                        }
                    }
                    values.clear()
                    values.put(MediaStore.Images.Media.IS_PENDING, 0)
                    context.contentResolver.update(uri, values, null, null)

                    MediaScannerConnection.scanFile(context, arrayOf(file.absolutePath), arrayOf("image/jpeg"), null)

                    val publicPath = "/Pictures/DualShots/$filename"
                    mainHandler.post { result.success(publicPath) }
                    return
                }
            } else {
                val picturesDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
                val dualShotsDir = File(picturesDir, "DualShots").apply { if (!exists()) mkdirs() }
                val destFile = File(dualShotsDir, filename)

                FileInputStream(file).use { input ->
                    FileOutputStream(destFile).use { output ->
                        input.copyTo(output)
                    }
                }

                MediaScannerConnection.scanFile(context, arrayOf(destFile.absolutePath), arrayOf("image/jpeg"), null)
                mainHandler.post { result.success(destFile.absolutePath) }
                return
            }

            mainHandler.post { result.success(path) }
        } catch (e: Exception) {
            Log.e(TAG, "Error saving to gallery MediaStore", e)
            mainHandler.post { result.error("SAVE_ERROR", e.message, null) }
        }
    }

    private fun switchRoles(result: MethodChannel.Result) {
        val temp = primaryCameraId
        primaryCameraId = secondaryCameraId
        secondaryCameraId = temp

        closePrimary()
        closeSecondary()
        openBothCameras()

        mainHandler.post { result.success(null) }
    }

    private fun closePrimary() {
        try {
            primarySession?.close()
            primarySession = null
            primaryCameraDevice?.close()
            primaryCameraDevice = null
            primaryImageReader?.close()
            primaryImageReader = null
        } catch (e: Exception) {
            Log.e(TAG, "Error closing primary", e)
        }
    }

    private fun closeSecondary() {
        try {
            secondarySession?.close()
            secondarySession = null
            secondaryCameraDevice?.close()
            secondaryCameraDevice = null
            secondaryImageReader?.close()
            secondaryImageReader = null
        } catch (e: Exception) {
            Log.e(TAG, "Error closing secondary", e)
        }
    }

    fun disposeAll() {
        isInitialized = false
        closePrimary()
        closeSecondary()
        stopBackgroundThread()
    }
}
