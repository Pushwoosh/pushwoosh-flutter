package com.pushwoosh.plugin;

import android.webkit.JavascriptInterface;
import com.pushwoosh.internal.utils.PWLog;
import org.json.JSONObject;
import org.json.JSONArray;
import org.json.JSONException;
import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

public class FlutterJavaScriptInterface {
    private static final String TAG = "FlutterJSInterface";
    private final String interfaceName;
    private final List<String> methodNames;
    private final AtomicLong callbackIdCounter = new AtomicLong(0);
    
    private static final Map<String, ResponseHandler> responseHandlers = new ConcurrentHashMap<>();
    
    private static class ResponseHandler {
        final String successCallback;
        final String errorCallback;
        
        ResponseHandler(String successCallback, String errorCallback) {
            this.successCallback = successCallback;
            this.errorCallback = errorCallback;
        }
    }

    public FlutterJavaScriptInterface(String interfaceName, List<String> methodNames) {
        this.interfaceName = interfaceName;
        this.methodNames = methodNames;
    }

    @JavascriptInterface
    public void callFlutterMethod(String methodName, String argumentsJson, String successCallback, String errorCallback) {
        try {
            // Security: Validate methodName against allowed methods
            if (!methodNames.contains(methodName)) {
                String errorMessage = "Method '" + methodName + "' is not allowed for interface '" + interfaceName + "'";
                PWLog.error(TAG, errorMessage);
                if (errorCallback != null && !errorCallback.isEmpty()) {
                    sendErrorCallback(errorCallback, errorMessage);
                }
                return;
            }
            
            String callbackId = interfaceName + "_" + callbackIdCounter.incrementAndGet();
            
            PWLog.debug(TAG, "JavaScript calling Flutter method: " + methodName + " with arguments: " + argumentsJson);
            
            if (successCallback != null || errorCallback != null) {
                responseHandlers.put(callbackId, new ResponseHandler(successCallback, errorCallback));
            }
            
            Map<String, Object> arguments = new HashMap<>();
            if (argumentsJson != null && !argumentsJson.isEmpty() && !argumentsJson.equals("{}")) {
                try {
                    JSONObject jsonArgs = new JSONObject(argumentsJson);
                    arguments = jsonObjectToMap(jsonArgs);
                } catch (JSONException e) {
                    PWLog.warn(TAG, "Failed to parse arguments JSON: " + argumentsJson + ", error: " + e.getMessage());
                }
            }
            
            Map<String, Object> callData = new HashMap<>();
            callData.put("interfaceName", interfaceName);
            callData.put("methodName", methodName);
            callData.put("arguments", arguments);
            callData.put("callbackId", callbackId);
            
            PushwooshPlugin.sendJavaScriptInterfaceCall(callData);
            
        } catch (Exception e) {
            PWLog.error(TAG, "Error calling Flutter method: " + methodName + ", error: " + e.getMessage());
            if (errorCallback != null && !errorCallback.isEmpty()) {
                sendErrorCallback(errorCallback, e.getMessage());
            }
        }
    }

    public static boolean sendResponse(String callbackId, boolean success, Object data, String error) {
        try {
            ResponseHandler handler = responseHandlers.remove(callbackId);
            if (handler != null) {
                String jsCode;
                if (success && handler.successCallback != null && !handler.successCallback.isEmpty()) {
                    String dataJson = "{}";
                    try {
                        if (data != null) {
                            Map<String, Object> resultMap = new HashMap<>();
                            resultMap.put("result", data);
                            dataJson = new JSONObject(resultMap).toString();
                        }
                    } catch (Exception e) {
                        PWLog.error(TAG, "Error serializing success data: " + e.getMessage());
                    }
                    jsCode = String.format("if (typeof %s === 'function') %s(%s);", 
                        handler.successCallback, handler.successCallback, dataJson);
                } else if (!success && handler.errorCallback != null && !handler.errorCallback.isEmpty()) {
                    String errorJson = "{}";
                    try {
                        Map<String, Object> errorMap = new HashMap<>();
                        errorMap.put("error", error != null ? error : "Unknown error");
                        errorJson = new JSONObject(errorMap).toString();
                    } catch (Exception e) {
                        PWLog.error(TAG, "Error serializing success data: " + e.getMessage());
                    }
                    jsCode = String.format("if (typeof %s === 'function') %s(%s);", 
                        handler.errorCallback, handler.errorCallback, errorJson);
                } else {
                    return true;
                }
                
                PWLog.debug(TAG, "Executing JavaScript callback: " + jsCode);
                executeJavaScript(jsCode);
                return true;
            } else {
                PWLog.warn(TAG, "No response handler found for callback ID: " + callbackId);
            }
        } catch (Exception e) {
            PWLog.error(TAG, "Error sending response for callback: " + callbackId + ", error: " + e.getMessage());
        }
        return false;
    }

    // Execute JavaScript - this is a placeholder for now
    // In a real implementation, this would need access to the WebView
    private static void executeJavaScript(String jsCode) {
        PWLog.debug(TAG, "Should execute JavaScript: " + jsCode);
    }

    private Map<String, Object> jsonObjectToMap(JSONObject jsonObject) throws JSONException {
        Map<String, Object> map = new HashMap<>();
        
        java.util.Iterator<String> keys = jsonObject.keys();
        while (keys.hasNext()) {
            String key = keys.next();
            Object value = jsonObject.get(key);
            if (value instanceof JSONObject) {
                map.put(key, jsonObjectToMap((JSONObject) value));
            } else if (value instanceof JSONArray) {
                map.put(key, jsonArrayToList((JSONArray) value));
            } else if (value == JSONObject.NULL) {
                map.put(key, null);
            } else {
                map.put(key, value);
            }
        }
        
        return map;
    }
    
    private List<Object> jsonArrayToList(JSONArray jsonArray) throws JSONException {
        List<Object> list = new ArrayList<>();
        
        for (int i = 0; i < jsonArray.length(); i++) {
            Object value = jsonArray.get(i);
            if (value instanceof JSONObject) {
                list.add(jsonObjectToMap((JSONObject) value));
            } else if (value instanceof JSONArray) {
                list.add(jsonArrayToList((JSONArray) value));
            } else if (value == JSONObject.NULL) {
                list.add(null);
            } else {
                list.add(value);
            }
        }
        
        return list;
    }
    
    private static void sendErrorCallback(String errorCallback, String errorMessage) {
        try {
            Map<String, Object> errorMap = new HashMap<>();
            errorMap.put("error", errorMessage != null ? errorMessage : "Unknown error");
            String errorJson = new JSONObject(errorMap).toString();
            
            String jsCode = String.format("if (typeof %s === 'function') %s(%s);", 
                errorCallback, errorCallback, errorJson);
            executeJavaScript(jsCode);
        } catch (Exception e) {
            PWLog.error(TAG, "Error sending error callback: " + e.getMessage());
        }
    }

    public String getInterfaceName() {
        return interfaceName;
    }

    public List<String> getMethodNames() {
        return methodNames;
    }
}