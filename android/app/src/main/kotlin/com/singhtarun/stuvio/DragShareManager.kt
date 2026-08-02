package com.singhtarun.stuvio

import android.app.Activity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class DragShareManager(
    private val activity: Activity
) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result
    ) {

        when (call.method) {

            "startDrag" -> {

                result.success(true)

            }

            else -> result.notImplemented()
        }
    }
}