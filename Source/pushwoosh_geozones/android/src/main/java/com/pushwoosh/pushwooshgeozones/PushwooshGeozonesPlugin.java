package com.pushwoosh.pushwooshgeozones;

import android.annotation.SuppressLint;

import com.pushwoosh.function.Callback;
import com.pushwoosh.location.PushwooshLocation;
import com.pushwoosh.location.network.exception.LocationNotAvailableException;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.BinaryMessenger;

import io.flutter.embedding.engine.plugins.FlutterPlugin;

public class PushwooshGeozonesPlugin implements MethodCallHandler, FlutterPlugin {

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        onAttachedToEngine(binding.getBinaryMessenger());
    }

    private static void onAttachedToEngine(BinaryMessenger messenger) {
        MethodChannel channel = new MethodChannel(messenger, "pushwoosh_geozones");
        channel.setMethodCallHandler(new PushwooshGeozonesPlugin());
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) { }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            case "startLocationTracking":
                onStartLocationTracking(result);
                break;
            case "stopLocationTracking":
                onStopLocationTracking(result);
                break;
            default:
                result.notImplemented();
        }
    }

    private void onStartLocationTracking(final Result result) {
        PushwooshLocation.startLocationTracking(new Callback<Void, LocationNotAvailableException>() {
            @Override
            public void process(com.pushwoosh.function.Result<Void, LocationNotAvailableException> resultRequest) {
                if (resultRequest.isSuccess()) {
                    result.success(resultRequest.getData());
                } else {
                    String error = resultRequest.getException().getMessage();
                    result.error(error, error, null);
                }
            }
        });
    }

    private void onStopLocationTracking(Result result) {
        PushwooshLocation.stopLocationTracking();
        result.success(null);
    }
}
