package com.pushwoosh.pushwooshinbox

import android.content.Context
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
import android.graphics.drawable.Drawable
import java.io.IOException
import android.content.res.AssetFileDescriptor
import android.content.res.AssetManager
import com.pushwoosh.inbox.ui.model.customizing.formatter.InboxDateFormatter
import java.io.FileInputStream
import java.text.DateFormat
import java.util.*
import android.graphics.drawable.BitmapDrawable
import android.graphics.Bitmap
import android.graphics.BitmapFactory




class PushwooshInboxPlugin() : MethodCallHandler {
    companion object {
        lateinit var registrar: Registrar
        @JvmStatic
        fun registerWith(registrar: Registrar): Unit {
            this.registrar = registrar;
            val channel = MethodChannel(registrar.messenger(), "pushwoosh_inbox")
            channel.setMethodCallHandler(PushwooshInboxPlugin())
        }
    }

    class PushwooshDateFormatter(val dataFormat: String?) : InboxDateFormatter {
        override fun transform(date: Date): String {
            return android.text.format.DateFormat.format(dataFormat, date).toString()
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result): Unit {
        if (call.method.equals("presentInboxUI")) {

            val context = AndroidPlatformModule.getApplicationContext()

            if (call.hasArgument("dateFormat")) {
                PushwooshInboxStyle.dateFormatter = PushwooshDateFormatter(call.argument("dateFormat"))
            }
            if (call.hasArgument("listEmptyImage")) {
                PushwooshInboxStyle.listEmptyImageDrawable = toDrawable(call.argument("listEmptyImage"))
            }
            if (call.hasArgument("listErrorImage")) {
                PushwooshInboxStyle.listErrorImageDrawable = toDrawable(call.argument("listErrorImage"))
            }
            if (call.hasArgument("defaultImage")) {
                PushwooshInboxStyle.defaultImageIconDrawable = toDrawable(call.argument("defaultImage"))
            }
            if (call.hasArgument("barTitle")) {
                PushwooshInboxStyle.barTitle = call.argument("barTitle")
            }
            if (call.hasArgument("listErrorMessage")) {
                PushwooshInboxStyle.listErrorMessage = call.argument("listErrorMessage")
            }
            if (call.hasArgument("listEmptyMessage")) {
                PushwooshInboxStyle.listEmptyText = call.argument("listEmptyMessage")
            }

            if (call.hasArgument("backgroundColor")) {
                PushwooshInboxStyle.backgroundColor = toColorInt(call.argument("backgroundColor"))
            }
            if (call.hasArgument("accentColor")) {
                PushwooshInboxStyle.accentColor = toColorInt(call.argument("accentColor"))
            }
            if (call.hasArgument("highlightColor")) {
                PushwooshInboxStyle.highlightColor = toColorInt(call.argument("highlightColor"))
            }

            if (call.hasArgument("barTextColor")) {
                PushwooshInboxStyle.barTextColor = toColorInt(call.argument("barTextColor"))
            }
            if (call.hasArgument("barBackgroundColor")) {
                PushwooshInboxStyle.barBackgroundColor = toColorInt(call.argument("barBackgroundColor"))
            }
            if (call.hasArgument("barAccentColor")) {
                PushwooshInboxStyle.barAccentColor = toColorInt(call.argument("barAccentColor"))
            }

            if (call.hasArgument("dividerColor")) {
                PushwooshInboxStyle.dividerColor = toColorInt(call.argument("dividerColor"))
            }

            if (call.hasArgument("dateColor")) {
                PushwooshInboxStyle.dateColor = toColorInt(call.argument("dateColor"))
            }
            if (call.hasArgument("readDateColor")) {
                PushwooshInboxStyle.readDateColor = toColorInt(call.argument("readDateColor"))
            }

            if (call.hasArgument("imageTypeColor")) {
                PushwooshInboxStyle.imageTypeColor = toColorInt(call.argument("imageTypeColor"))
            }
            if (call.hasArgument("readImageTypeColor")) {
                PushwooshInboxStyle.readImageTypeColor = toColorInt(call.argument("readImageTypeColor"))
            }

            if (call.hasArgument("descriptionColor")) {
                PushwooshInboxStyle.descriptionColor = toColorInt(call.argument("descriptionColor"))
            }
            if (call.hasArgument("readDescriptionColor")) {
                PushwooshInboxStyle.readDescriptionColor = toColorInt(call.argument("readDescriptionColor"))
            }

            if (call.hasArgument("titleColor")) {
                PushwooshInboxStyle.titleColor = toColorInt(call.argument("titleColor"))
            }
            if (call.hasArgument("readTitleColor")) {
                PushwooshInboxStyle.readTitleColor = toColorInt(call.argument("readTitleColor"))
            }


            val intent = Intent(context, InboxActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context!!.startActivity(intent)
        } else {
            result.notImplemented()
        }
    }

    private fun toColorInt(colorString: String?): Int? {
        val color = Color.parseColor(colorString)
        return color
    }

    private fun toDrawable(imageString: String?): Drawable? {
        val registrar: Registrar = PushwooshInboxPlugin.registrar
        val assetManager = registrar.context().getAssets()
        val key = registrar.lookupKeyForAsset(imageString)
        val fd: AssetFileDescriptor = assetManager.openFd(key)
        val fileInputStream: FileInputStream = fd.createInputStream()
        val bitmap = BitmapFactory.decodeStream(fileInputStream)
        bitmap.density = Bitmap.DENSITY_NONE
        val drawable = BitmapDrawable(bitmap)
        return drawable
    }
}