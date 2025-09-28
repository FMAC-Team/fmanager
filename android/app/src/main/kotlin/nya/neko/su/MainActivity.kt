package nya.neko.su

import android.graphics.Color
import android.os.Build
import android.os.Bundle
import androidx.core.graphics.ColorUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "fmac/color"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "getAccentColor") {
                val color = getSystemAccentColor()
                result.success(color)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getSystemAccentColor(): Int {
        val baseColor = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Get system accent color on Android 12+
            getColor(android.R.color.system_accent1_500)
        } else {
            // Fallback color for older Android versions
            Color.parseColor("#6200EE")
        }

        // The ratio to blend with white. 0.0 is the original color, 1.0 is pure white.
        // A value of 0.2-0.4 usually works well for a subtle lightening effect.
        val lightenRatio = 0.6f

        // Blend the base color with white to make it lighter
        return ColorUtils.blendARGB(baseColor, Color.WHITE, lightenRatio)
    }
}
