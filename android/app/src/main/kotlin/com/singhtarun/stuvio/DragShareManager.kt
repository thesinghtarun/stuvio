package com.singhtarun.stuvio

import android.app.Activity
import android.content.ClipData
import android.net.Uri
import android.view.View
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.text.TextUtils
import android.view.Gravity
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import com.singhtarun.stuvio.FileCardDragShadowBuilder

class DragShareManager(
    private val activity: Activity
) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result
    ) {

        when (call.method) {

            "startDrag" -> {

                val path = call.argument<String>("filePath")
                val displayTitleArg  = call.argument<String>("title")

                if (path == null) {
                    result.error("NO_PATH", "File path missing", null)
                    return
                }

                val file = File(path)

val displayTitle =
    if (!displayTitleArg.isNullOrBlank()) displayTitleArg
    else file.name

                if (!file.exists()) {
                    result.error("NO_FILE", "File doesn't exist", null)
                    return
                }

                val uri = FileProvider.getUriForFile(
                    activity,
                    "${activity.packageName}.fileprovider",
                    file
                )

                val clip = ClipData.newUri(
                    activity.contentResolver,
                    file.name,
                    uri
                )

                // Create a small drag card
val container = LinearLayout(activity).apply {

    orientation = LinearLayout.HORIZONTAL

    gravity = Gravity.CENTER_VERTICAL

    setPadding(40, 30, 40, 30)

    background = GradientDrawable().apply {
        setColor(Color.WHITE)
        cornerRadius = 36f
    }

    elevation = 24f
}

// PDF icon
val icon = ImageView(activity).apply {

    setImageResource(android.R.drawable.ic_menu_save)

    layoutParams = LinearLayout.LayoutParams(80, 80)
}

// Text column
val textLayout = LinearLayout(activity).apply {

    orientation = LinearLayout.VERTICAL

    setPadding(24, 0, 0, 0)
}

// Title
val title = TextView(activity).apply {

    text = file.name

    textSize = 16f

    setTypeface(null, Typeface.BOLD)

    setTextColor(Color.BLACK)

    maxLines = 1

    ellipsize = TextUtils.TruncateAt.END
}

// Subtitle
val subtitle = TextView(activity).apply {

    text = "StudyVault"

    textSize = 13f

    setTextColor(Color.GRAY)
}

textLayout.addView(title)
textLayout.addView(subtitle)

container.addView(icon)
container.addView(textLayout)

// Measure the card
container.measure(
    View.MeasureSpec.UNSPECIFIED,
    View.MeasureSpec.UNSPECIFIED
)

container.layout(
    0,
    0,
    container.measuredWidth,
    container.measuredHeight
)

val flags =
    View.DRAG_FLAG_GLOBAL or
    View.DRAG_FLAG_GLOBAL_URI_READ

// Use an attached view to start the drag
val rootView = activity.window.decorView

val started = rootView.startDragAndDrop(
    clip,
    FileCardDragShadowBuilder(displayTitle),
    null,
    flags
)

                result.success(started)
            }

            else -> result.notImplemented()
        }
    }
}