package com.pushwoosh.pushwooshinbox

import android.content.Intent
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.PluginRegistry.Registrar
import com.pushwoosh.internal.platform.AndroidPlatformModule
import com.pushwoosh.inbox.ui.presentation.view.activity.InboxActivity

class PushwooshInboxPlugin(): MethodCallHandler {
  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar): Unit {
      val channel = MethodChannel(registrar.messenger(), "pushwoosh_inbox")
      channel.setMethodCallHandler(PushwooshInboxPlugin())
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result): Unit {
    if(call.method.equals("presentInboxUI")){
      val applicationContext = AndroidPlatformModule.getApplicationContext()
      applicationContext!!.startActivity(Intent(applicationContext, InboxActivity::class.java))
        result.notImplemented()
    }
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else {
      result.notImplemented()
    }
  }
}
