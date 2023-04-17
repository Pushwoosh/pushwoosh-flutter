package com.pushwoosh.pushwooshinbox;

import android.content.Context;
import android.content.Intent;
import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.os.Bundle;
import android.util.Log;

import com.pushwoosh.function.Callback;
import com.pushwoosh.inbox.PushwooshInbox;
import com.pushwoosh.inbox.data.InboxMessage;
import com.pushwoosh.inbox.exception.InboxMessagesException;

import com.pushwoosh.inbox.ui.PushwooshInboxStyle;
import com.pushwoosh.inbox.ui.model.customizing.formatter.InboxDateFormatter;
import com.pushwoosh.inbox.ui.presentation.view.activity.InboxActivity;
import com.pushwoosh.internal.platform.AndroidPlatformModule;
import com.pushwoosh.internal.utils.JsonUtils;
import com.pushwoosh.internal.utils.PWLog;

import java.io.FileInputStream;
import java.io.IOException;
import java.util.Date;
import java.util.ArrayList;
import java.util.Collection;

import org.json.JSONException;
import org.json.JSONObject;

import io.flutter.FlutterInjector;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.BinaryMessenger;

import io.flutter.embedding.engine.plugins.FlutterPlugin;

public class PushwooshInboxPlugin implements MethodCallHandler, FlutterPlugin {
    private static final String TAG = "PushwooshInboxPlugin";
    private static int messagesWithNoAction = 0;
    public static Context context;

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        onAttachedToEngine(binding.getBinaryMessenger());
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        context = null;
    }

    private static void onAttachedToEngine(BinaryMessenger messenger) {
        MethodChannel channel = new MethodChannel(messenger, "pushwoosh_inbox");
        channel.setMethodCallHandler(new PushwooshInboxPlugin());
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "presentInboxUI":
                presentInboxUI(call);
                break;
            case "messagesWithNoActionPerformedCount":
                messagesWithNoActionPerformedCount(result);
                break;
            case "unreadMessagesCount":
                unreadMessagesCount(result);
                break;
            case "messagesCount":
                messagesCount(result);
                break;
            case "loadMessages":
                loadMessages(result);
                break;
            case "loadCachedMessages":
                loadCachedMessages(result);
                break;
            case "readMessage":
                readMessage(call, result);
                break;
            case "readMessages":
                readMessages(call, result);
            case "deleteMessage":
                deleteMessage(call, result);
                break;
            case "deleteMessages":
                deleteMessages(call, result);
                break;    
            case "performAction":
                performAction(call, result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private static void messagesWithNoActionPerformedCount(final Result result) {
        PushwooshInbox.messagesWithNoActionPerformedCount(new Callback<Integer, InboxMessagesException>() {
            @Override
            public void process(com.pushwoosh.function.Result<Integer, InboxMessagesException> resultRequest) {
                if (resultRequest.isSuccess()) {
                    result.success(resultRequest.getData());
                } else {
                    sendResultException(result, resultRequest.getException());
                }
            }
        });
    }

    private static void unreadMessagesCount(final Result result) {
        PushwooshInbox.unreadMessagesCount(new Callback<Integer, InboxMessagesException>() {
            @Override
            public void process(com.pushwoosh.function.Result<Integer, InboxMessagesException> resultRequest) {
                if (resultRequest.isSuccess()) {
                    result.success(resultRequest.getData());
                } else {
                    sendResultException(result, resultRequest.getException());
                }
            }
        });
    }

    private static void messagesCount(final Result result) {
        PushwooshInbox.messagesCount(new Callback<Integer, InboxMessagesException>() {
            @Override
            public void process(com.pushwoosh.function.Result<Integer, InboxMessagesException> resultRequest) {
                if (resultRequest.isSuccess()) {
                    result.success(resultRequest.getData());
                } else {
                    sendResultException(result, resultRequest.getException());
                }
            }
        });
    }

    private static void loadMessages(final Result result) {
        PushwooshInbox.loadMessages(new Callback<Collection<InboxMessage>, InboxMessagesException>() {
            @Override
            public void process(com.pushwoosh.function.Result<Collection<InboxMessage>, InboxMessagesException> resultRequest) {
                if (resultRequest.isSuccess()) {
                    ArrayList<InboxMessage> inboxMessageList = new ArrayList<>(resultRequest.getData());
                    ArrayList<String> objectArrayList = new ArrayList<>();
                    for (InboxMessage message: inboxMessageList) {
                        objectArrayList.add(toJson(message).toString());
                    }
                    result.success(objectArrayList);
                } else {
                    sendResultException(result, resultRequest.getException());
                }
            }
        });
    }
    
    private static void loadCachedMessages(final Result result) {
        try {
            PushwooshInbox.loadCachedMessages(new Callback<Collection<InboxMessage>, InboxMessagesException>() {
                @Override
                public void process(com.pushwoosh.function.Result<Collection<InboxMessage>, InboxMessagesException> resultRequest) {
                    if (resultRequest.isSuccess()) {
                        ArrayList<InboxMessage> inboxMessageList = new ArrayList<>(resultRequest.getData());
                        ArrayList<String> objectArrayList = new ArrayList<>();
                        for (InboxMessage message: inboxMessageList) {
                            objectArrayList.add(toJson(message).toString());
                        }
                        result.success(objectArrayList);
                    } else {
                        sendResultException(result, resultRequest.getException());
                    }
                }
            }, null, -1);
        } catch (Exception e) {
            sendResultException(result, e);
        }
    }
    
    private static void readMessage(MethodCall call, Result result) {
        PushwooshInbox.readMessage((String) call.argument("code"));
    }
    
    private static void readMessages(MethodCall call, Result result) {
        PushwooshInbox.readMessages((Collection<String>) call.argument("codes"));
    }
    
    private static void deleteMessage(MethodCall call, Result result) {
        PushwooshInbox.deleteMessage((String) call.argument("code"));
    }

    private static void deleteMessages(MethodCall call, Result result) {
        PushwooshInbox.deleteMessages((Collection<String>) call.argument("codes"));
    }
    
    private static void performAction(MethodCall call, Result result) {
        PushwooshInbox.performAction((String) call.argument("code"));
    }

    private static JSONObject toJson(InboxMessage message) {
        JSONObject object = new JSONObject();
        try {
            object.put("code", message.getCode())
                    .put("title", message.getTitle())
                    .put("imageUrl", message.getImageUrl())
                    .put("message",message.getMessage())
                    .put("sendDate",message.getISO8601SendDate())
                    .put("messageType", message.getType().getCode())
                    .put("bannerUrl", message.getBannerUrl())
                    .put("isRead",message.isRead())
                    .put("actionParams",message.getActionParams())
                    .put("isActionPerformed",message.isActionPerformed());

            Bundle bundle = JsonUtils.jsonStringToBundle( message.getActionParams());
            String customData = bundle.getString("u");
            if (customData != null) {
                object.put("customData", customData);
            }
        } catch (JSONException e) {
            Log.e("PushwooshInbox", "Failed to fetch inbox message :" + e.getMessage());
        }
        return object;
    }



    private static void presentInboxUI(MethodCall call) {
        Context context = AndroidPlatformModule.getApplicationContext();
        if (call.hasArgument("dateFormat")) {
            PushwooshInboxStyle.INSTANCE.setDateFormatter(
                    new PushwooshDateFormatter((String) call.argument("dateFormat")));
        }
        if (call.hasArgument("listEmptyImage")) {
            Drawable drawable = toDrawable((String) call.argument("listErrorImage"));
            if (drawable != null) {
                PushwooshInboxStyle.INSTANCE.setListEmptyImageDrawable(drawable);
            }
        }
        if (call.hasArgument("listErrorImage")) {
            Drawable drawable = toDrawable((String) call.argument("listErrorImage"));
            if (drawable != null) {
                PushwooshInboxStyle.INSTANCE.setListErrorImageDrawable(drawable);
            }
        }
        if (call.hasArgument("defaultImage")) {
            Drawable drawable = toDrawable((String) call.argument("defaultImage"));
            if (drawable != null) {
                PushwooshInboxStyle.INSTANCE.setDefaultImageIconDrawable(drawable);
            }
        }
        if (call.hasArgument("barTitle")) {
            PushwooshInboxStyle.INSTANCE.setBarTitle((String) call.argument("barTitle"));
        }
        if (call.hasArgument("listErrorMessage")) {
            PushwooshInboxStyle.INSTANCE.setListErrorMessage((String) call.argument("listErrorMessage"));
        }
        if (call.hasArgument("listEmptyMessage")) {
            PushwooshInboxStyle.INSTANCE.setListEmptyText((String) call.argument("listEmptyMessage"));
        }
        if (call.hasArgument("backgroundColor")) {
            PushwooshInboxStyle.INSTANCE.setBackgroundColor(toColorInt((String) call.argument("backgroundColor")));
        }
        if (call.hasArgument("accentColor")) {
            PushwooshInboxStyle.INSTANCE.setAccentColor(toColorInt((String) call.argument("accentColor")));
        }
        if (call.hasArgument("highlightColor")) {
            PushwooshInboxStyle.INSTANCE.setHighlightColor(toColorInt((String) call.argument("highlightColor")));
        }
        if (call.hasArgument("barTextColor")) {
            PushwooshInboxStyle.INSTANCE.setBarTextColor(toColorInt((String) call.argument("barTextColor")));
        }
        if (call.hasArgument("barBackgroundColor")) {
            PushwooshInboxStyle.INSTANCE.setBarBackgroundColor(toColorInt((String) call.argument("barBackgroundColor")));
        }
        if (call.hasArgument("barAccentColor")) {
            PushwooshInboxStyle.INSTANCE.setBarAccentColor(toColorInt((String) call.argument("barAccentColor")));
        }
        if (call.hasArgument("dividerColor")) {
            PushwooshInboxStyle.INSTANCE.setDividerColor(toColorInt((String) call.argument("dividerColor")));
        }
        if (call.hasArgument("dateColor")) {
            PushwooshInboxStyle.INSTANCE.setDateColor(toColorInt((String) call.argument("dateColor")));
        }
        if (call.hasArgument("readDateColor")) {
            PushwooshInboxStyle.INSTANCE.setReadDateColor(toColorInt((String) call.argument("readDateColor")));
        }
        if (call.hasArgument("imageTypeColor")) {
            PushwooshInboxStyle.INSTANCE.setImageTypeColor(toColorInt((String) call.argument("imageTypeColor")));
        }
        if (call.hasArgument("readImageTypeColor")) {
            PushwooshInboxStyle.INSTANCE.setReadImageTypeColor(toColorInt((String) call.argument("readImageTypeColor")));
        }
        if (call.hasArgument("descriptionColor")) {
            PushwooshInboxStyle.INSTANCE.setDescriptionColor(toColorInt((String) call.argument("descriptionColor")));
        }
        if (call.hasArgument("readDescriptionColor")) {
            PushwooshInboxStyle.INSTANCE.setReadDescriptionColor(toColorInt((String) call.argument("readDescriptionColor")));
        }
        if (call.hasArgument("titleColor")) {
            PushwooshInboxStyle.INSTANCE.setTitleColor(toColorInt((String) call.argument("titleColor")));
        }
        if (call.hasArgument("readTitleColor")) {
            PushwooshInboxStyle.INSTANCE.setReadTitleColor(toColorInt((String) call.argument("readTitleColor")));
        }
        Intent intent = new Intent(context, InboxActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        context.startActivity(intent);
    }

    private static int toColorInt(String colorString) {
        return Color.parseColor(colorString);
    }

    private static Drawable toDrawable(String imageString) {
        AssetManager assetManager = context.getAssets();
        String key = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(imageString);
        try {
            AssetFileDescriptor fd = assetManager.openFd(key);
            FileInputStream fileInputStream = fd.createInputStream();
            Bitmap bitmap = BitmapFactory.decodeStream(fileInputStream);
            bitmap.setDensity(Bitmap.DENSITY_NONE);
            Drawable drawable = new BitmapDrawable(AndroidPlatformModule.getApplicationContext().getResources(), bitmap);
            return drawable;
        } catch (IOException e) {
            PWLog.error(TAG, "Failed to load image", e);
            return null;
        }
    }

    private static void sendResultException(Result result, Exception e) {
        if (e == null) {
            return;
        }
        String message = e.getMessage();
        result.error(e.getClass().getSimpleName(), message, Log.getStackTraceString(e));
    }

    private static class PushwooshDateFormatter implements InboxDateFormatter {
        private final String dataFormat;

        public PushwooshDateFormatter(String dataFormat) {
            this.dataFormat = dataFormat;
        }

        @Override
        public String transform(Date date) {
            return android.text.format.DateFormat.format(dataFormat, date).toString();
        }
    }
}
