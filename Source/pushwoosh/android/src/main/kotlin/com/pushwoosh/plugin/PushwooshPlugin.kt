package com.pushwoosh.plugin

import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.PluginRegistry.Registrar
import com.pushwoosh.Pushwoosh
import android.os.Handler
import android.support.annotation.MainThread
import com.pushwoosh.exception.PushwooshException

import com.pushwoosh.notification.NotificationServiceExtension
import com.pushwoosh.notification.PushMessage
import com.pushwoosh.inapp.PushwooshInApp
import com.pushwoosh.tags.Tags
import org.json.JSONObject
import org.json.JSONArray
import com.pushwoosh.internal.utils.PWLog
import com.pushwoosh.internal.network.NetworkException
import android.util.Log
import io.flutter.plugin.common.StandardMethodCodec
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.BinaryMessenger.*

class PushwooshPlugin() : MethodCallHandler {

    companion object {
        var listen: Boolean = false
        var showForegroundPush: Boolean = true
        lateinit var channel: MethodChannel
        public lateinit var receiveChannel: EventChannel
        public lateinit var acceptChannel: EventChannel

        public lateinit var receiveHandler: StremaHandler
        public lateinit var acceptHandler: StremaHandler


        private lateinit var messenger: BinaryMessenger

        @JvmStatic
        fun registerWith(registrar: Registrar): Unit {
            messenger = registrar.messenger()
            channel = MethodChannel(messenger, "pushwoosh")
            receiveChannel = EventChannel(messenger, "pushwoosh/receive")
            acceptChannel = EventChannel(messenger, "pushwoosh/accept")
            channel.setMethodCallHandler(PushwooshPlugin())

            receiveHandler = StremaHandler()
            receiveChannel.setStreamHandler(receiveHandler)
            acceptHandler = StremaHandler()
            acceptChannel.setStreamHandler(acceptHandler)
        }

        class StremaHandler : EventChannel.StreamHandler {
            var events: EventChannel.EventSink? = null

            fun sendEvent(map: Map<String, Any>, fromBackground: Boolean) {
                events?.success(convertMap(map, fromBackground))
            }

            fun convertMap(map: Map<String, Any>, fromBackground: Boolean) : Map<String, Any> {
                val mapForFlutter = HashMap<String, Any>()
                val title = map["title"]
                mapForFlutter.put("title", if (title == null) "" else title)
                val body = map["body"]
                mapForFlutter.put("message",  if (body == null) "" else body)
                val customData = map["customData"]
                mapForFlutter.put("customData", if (customData == null) HashMap<String, Any>() else customData)
                mapForFlutter.put("fromBackground", fromBackground)
                mapForFlutter.put("payload", map)
                return mapForFlutter
            }

            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                this.events = events;
            }

            override fun onCancel(arguments: Any?) {

            }

        }

        @JvmStatic
        fun onMessageReceived(map: Map<String, Any>, fromBackground: Boolean) {
            receiveHandler?.sendEvent(map, fromBackground)
        }

        @JvmStatic
        fun onMessageAccepted(map: Map<String, Any>, fromBackground: Boolean) {
            acceptHandler?.sendEvent(map, fromBackground)
        }

        @JvmStatic
        fun callToFlutter(methode: String, arg: Map<String, Any>) {
            if (channel != null && listen)
                PushwooshPlugin.channel.invokeMethod(methode, arg)
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result): Unit {
        val instance: Pushwoosh = Pushwoosh.getInstance()
        when (call.method) {
            "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
            "initialize" -> initialize(call, instance)
            "getInstance" -> result.success(instance)
            "registerForPushNotifications" -> registerForPushNotifications(call, result)
            "unregisterForPushNotifications" -> unregisterForPushNotifications(call, result)
            "getPushToken" -> result.success(instance.getPushToken())
            "getHWID" -> result.success(instance.getHwid())
            "setTags" -> setTags(call, result)
            "getTags" -> getTags(call, result)
            "startListening" -> PushwooshPlugin.listen = true;
            "setShowForegroundPush" -> PushwooshPlugin.showForegroundPush = call.argument("show_foreground_push") ?: false
            "showForegroundAlert" -> showForegroundAlert(call, result)
            "postEvent" -> postEvent(call, result)
            else -> result.notImplemented()
        }
    }

    private fun registerForPushNotifications(call: MethodCall, result: Result) {
        Pushwoosh.getInstance().registerForPushNotifications { resultRequest ->
            if (resultRequest.isSuccess()) {
                result.success(resultRequest.getData())
            } else {
                sendResultException(result, resultRequest.exception)
            }
        }
    }

    private fun sendResultException(result: Result, e: PushwooshException?) {
        if (e == null) {
            return
        }
        val message = e?.message
        result.error(e.javaClass.simpleName, message, Log.getStackTraceString(e))
    }

    private fun unregisterForPushNotifications(call: MethodCall, result: Result) {
        Pushwoosh.getInstance().unregisterForPushNotifications { resultRequest ->
            if (resultRequest.isSuccess()) {
                result.success(resultRequest.getData())
            } else {
                sendResultException(result, resultRequest.exception)
            }
        }
    }

    private fun getTags(call: MethodCall, result: Result) {
        Pushwoosh.getInstance().getTags { resultRequest ->
            if (resultRequest.isSuccess()) {
                val data = resultRequest.data
                val map = data?.map
                val mapParsed = HashMap<String, Any>()
                map?.forEach { it ->
                    if (it.value is JSONArray) {
                        val value = data.getList(it.key)
                        if (value != null)
                            mapParsed.put(it.key, value)
                    } else {
                        mapParsed.put(it.key, it.value)
                    }
                }
                result.success(mapParsed)
            } else {
                sendResultException(result, resultRequest.exception)
            }
        }
    }

    private fun setTags(call: MethodCall, result: Result) {
        val map: Map<String, String>? = call.argument("tags")
        if (map == null)
            return
        val json = JSONObject(map)
        Pushwoosh.getInstance().sendTags(Tags.fromJson(json), { resultRequest ->
            if (resultRequest.isSuccess()) {
                result.success(null)
            } else {
                sendResultException(result, resultRequest.exception)
            }
        })
    }

    private fun showForegroundAlert(call: MethodCall, result: Result) {
        if (call.arguments == null) {
            result.success(PushwooshPlugin.showForegroundPush)
        } else {
            PushwooshPlugin.showForegroundPush = call.arguments as Boolean
        }
    }

    private fun postEvent(call: MethodCall, result: Result) {
        val args: ArrayList<Any> = call.arguments as ArrayList<Any>
        val method: String = args[0] as String
        val map: Map<String, Any> = args[1] as Map<String, Any>
        val jsonObject = JSONObject(map)
        PushwooshInApp.getInstance().postEvent(method, Tags.fromJson(jsonObject))
        result.success(null)
    }

    private fun initialize(call: MethodCall, instance: Pushwoosh) {
        val appId: String? = call.argument("app_id")
        if (appId != null)
            instance.setAppId(appId)

        val sendId: String? = call.argument("sender_id")
        if (sendId != null)
            instance.setSenderId(sendId)
    }
}


