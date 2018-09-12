package com.pushwoosh.pushwooshinbox

import android.content.Intent
import android.graphics.Color
import com.pushwoosh.inbox.ui.PushwooshInboxStyle
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.PluginRegistry.Registrar
import com.pushwoosh.internal.platform.AndroidPlatformModule
import com.pushwoosh.inbox.ui.presentation.view.activity.InboxActivity

class PushwooshInboxPlugin() : MethodCallHandler {
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar): Unit {
            val channel = MethodChannel(registrar.messenger(), "pushwoosh_inbox")
            channel.setMethodCallHandler(PushwooshInboxPlugin())
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result): Unit {
        if (call.method.equals("presentInboxUI")) {
/*        val dateFormat: String
        val defaultImageName: String
        val unreadImage: String
        val listErrorImage: String
        val listEmptyImage: String
        */

            PushwooshInboxStyle.barTitle = call.argument("barTitle")
            PushwooshInboxStyle.listErrorMessage = call.argument("listErrorMessage")
            PushwooshInboxStyle.listEmptyText = call.argument("listEmptyMessage")

            PushwooshInboxStyle.backgroundColor = toColorInte(call.argument("backgroundColor"))
            PushwooshInboxStyle.accentColor = toColorInte(call.argument("accentColor"))
            PushwooshInboxStyle.highlightColor = toColorInte(call.argument("highlightColor"))

            PushwooshInboxStyle.barTextColor = toColorInte(call.argument("barTextColor"))
            PushwooshInboxStyle.barBackgroundColor = toColorInte(call.argument("barBackgroundColor"))
            PushwooshInboxStyle.barAccentColor = toColorInte(call.argument("barAccentColor"))

            PushwooshInboxStyle.dividerColor = toColorInte(call.argument("dividerColor"))


            PushwooshInboxStyle.dateColor = toColorInte(call.argument("dateColor"))
            PushwooshInboxStyle.readDateColor = toColorInte(call.argument("readDateColor"))

            PushwooshInboxStyle.imageTypeColor = toColorInte(call.argument("imageTypeColor"))
            PushwooshInboxStyle.readImageTypeColor = toColorInte(call.argument("readImageTypeColor"))

            PushwooshInboxStyle.descriptionColor = toColorInte(call.argument("descriptionColor"))
            PushwooshInboxStyle.readDescriptionColor = toColorInte(call.argument("readDescriptionColor"))

            PushwooshInboxStyle.titleColor = toColorInte(call.argument("titleColor"))
            PushwooshInboxStyle.readTitleColor = toColorInte(call.argument("readTitleColor"))

            val applicationContext = AndroidPlatformModule.getApplicationContext()
            val intent = Intent(applicationContext, InboxActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            applicationContext!!.startActivity(intent)
        } else {
            result.notImplemented()
        }
    }

    private fun toColorInte(colorString: String?): Int? {
        val color = Color.parseColor(colorString)
        return color
    }
}
