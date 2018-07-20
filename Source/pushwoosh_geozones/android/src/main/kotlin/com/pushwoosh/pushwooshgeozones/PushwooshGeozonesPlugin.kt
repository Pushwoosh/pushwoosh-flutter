package com.pushwoosh.pushwooshgeozones

import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.PluginRegistry.Registrar
import com.pushwoosh.location.PushwooshLocation
import android.util.Log

class PushwooshGeozonesPlugin() : MethodCallHandler {
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar): Unit {
            val channel = MethodChannel(registrar.messenger(), "pushwoosh_geozones")
            channel.setMethodCallHandler(PushwooshGeozonesPlugin())
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result): Unit {
        when (call.method) {
            "startLocationTracking" -> {
                PushwooshLocation.startLocationTracking { resultRequest ->
                    if (resultRequest.isSuccess()) {
                        result.success(resultRequest.data)
                    } else {
                        val error = resultRequest.exception!!.message
                        result.error(error, error, null)
                    }
                }
            }
            "stopLocationTracking" -> {
                PushwooshLocation.stopLocationTracking()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}
