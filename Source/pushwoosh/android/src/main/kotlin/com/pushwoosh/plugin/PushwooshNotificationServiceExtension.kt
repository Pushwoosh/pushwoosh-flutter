package com.pushwoosh.plugin


import com.pushwoosh.internal.utils.PWLog
import android.content.pm.PackageManager
import com.pushwoosh.notification.NotificationServiceExtension
import com.pushwoosh.notification.PushMessage
import com.pushwoosh.internal.utils.JsonUtils


class PushwooshNotificationServiceExtension : NotificationServiceExtension() {
    private var showForegroundPush: Boolean = false
    private val TAG = "PushwooshNotificationServiceExtension"

    init {
        try {
            val packageName = applicationContext?.packageName
            val ai =  applicationContext?.packageManager?.getApplicationInfo(packageName, PackageManager.GET_META_DATA)

            if (ai?.metaData != null) {
                showForegroundPush = ai.metaData.getBoolean("PW_BROADCAST_PUSH", false) || ai.metaData.getBoolean("com.pushwoosh.foreground_push", false)
            }
        } catch (e: Exception) {
            PWLog.error(TAG, "Failed to read AndroidManifest metaData", e)
        }

        PWLog.debug(TAG, "showForegroundPush = $showForegroundPush")
    }


    override fun onMessageReceived(pushMessage: PushMessage): Boolean {
        val appOnForeground = isAppOnForeground()
        PushwooshPlugin.onMessageReceived(JsonUtils.jsonToMap(pushMessage.toJson()), !appOnForeground)
        return !PushwooshPlugin.showForegroundPush && appOnForeground || super.onMessageReceived(pushMessage)
    }


    override fun onMessageOpened(pushMessage: PushMessage) {
        val appOnForeground = isAppOnForeground()
        PushwooshPlugin.onMessageAccepted(JsonUtils.jsonToMap(pushMessage.toJson()), !appOnForeground)
    }
}