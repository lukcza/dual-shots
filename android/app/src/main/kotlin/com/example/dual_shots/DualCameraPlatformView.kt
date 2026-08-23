package com.example.dual_shots

import android.content.Context
import android.graphics.SurfaceTexture
import android.view.TextureView
import android.view.View
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class DualCameraPlatformView(
    context: Context,
    id: Int,
    creationParams: Map<String?, Any?>?
) : PlatformView, TextureView.SurfaceTextureListener {

    private val textureView: TextureView = TextureView(context)
    private val lensType: String = (creationParams?.get("lens") as? String) ?: "primary"

    init {
        textureView.surfaceTextureListener = this
    }

    override fun getView(): View {
        return textureView
    }

    override fun onSurfaceTextureAvailable(surface: SurfaceTexture, width: Int, height: Int) {
        if (lensType == "primary") {
            NativeDualCameraController.attachPrimarySurface(textureView)
        } else {
            NativeDualCameraController.attachSecondarySurface(textureView)
        }
    }

    override fun onSurfaceTextureSizeChanged(surface: SurfaceTexture, width: Int, height: Int) {}

    override fun onSurfaceTextureDestroyed(surface: SurfaceTexture): Boolean {
        if (lensType == "primary") {
            NativeDualCameraController.detachPrimary()
        } else {
            NativeDualCameraController.detachSecondary()
        }
        return true
    }

    override fun onSurfaceTextureUpdated(surface: SurfaceTexture) {}

    override fun dispose() {
        if (lensType == "primary") {
            NativeDualCameraController.detachPrimary()
        } else {
            NativeDualCameraController.detachSecondary()
        }
    }
}

class DualCameraPlatformViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val params = args as? Map<String?, Any?>
        return DualCameraPlatformView(context, viewId, params)
    }
}
