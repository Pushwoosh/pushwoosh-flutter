import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

/// This class is designed to customize the Inbox appearance
class PWInboxStyle {

  /// Inbox message date format. For example: "dd.MMMM.yyyy"
  String? dateFormat;

  /// The default icon in the cell next to the message; if not specified, the app icon is used
  String? defaultImage;

  /// The appearance of the unread messages mark (iOS only)
  String? unreadImage;

  /// The image which is displayed if an error occurs and the list of inbox messages is empty
  String? listErrorImage;

  /// The image which is displayed if the list of inbox messages is empty
  String? listEmptyImage;

  /// The error text which is displayed when an error occurs; cannot be localized
  String? listErrorMessage;

  /// The text which is displayed if the list of inbox messages is empty; cannot be localized
  String? listEmptyMessage;

  /// The default bar title text
  String? barTitle;

  /// The accent color
  String? accentColor;

  /// The default background color
  String? backgroundColor;

  /// The default selection color
  String? highlightColor;

  /// The default text color (iOS only)
  String? defaultTextColor;

  /// The color of the unread message action icon (Deep Link, URL, etc.). By default used [accentColor] (Android only)
  String? imageTypeColor;

  /// The color of the read message action icon. By default used [readDateColor] (Android only)
  String? readImageTypeColor;

  /// The color of message titles
  String? titleColor;

  /// The color of message titles if message was readed (Android only)
  String? readTitleColor;

  /// The color of messages descriptions
  String? descriptionColor;

  /// The color of messages descriptions if message was readed (Android only)
  String? readDescriptionColor;

  /// The color of message dates
  String? dateColor;

  /// The color of message dates if message was readed (Android only)
  String? readDateColor;

  /// The color of the separator
  String? dividerColor;

  /// The default bar color
  String? barBackgroundColor;

  /// The default back button color
  String? barAccentColor;

  /// The default bar accent color
  String? barTextColor;

  Map<String, dynamic> _dictionaryRepresentation() {
    Map<String, dynamic> params = Map();

    if (dateFormat != null) {
      params['dateFormat'] = dateFormat;
    }

    if (defaultImage != null) {
      params['defaultImage'] = defaultImage;
    }

    if (unreadImage != null) {
      params['unreadImage'] = unreadImage;
    }

    if (listErrorImage != null) {
      params['listErrorImage'] = listErrorImage;
    }

    if (listEmptyImage != null) {
      params['listEmptyImage'] = listEmptyImage;
    }

    if (listErrorMessage != null) {
      params['listErrorMessage'] = listErrorMessage;
    } 

    if (listEmptyMessage != null) {
      params['listEmptyMessage'] = listEmptyMessage;
    } 

    if (barTitle != null) {
      params['barTitle'] = barTitle;
    }

    if (accentColor != null) {
      params['accentColor'] = accentColor;
    }

    if (backgroundColor != null) {
      params['backgroundColor'] = backgroundColor;
    }

    if (highlightColor != null) {
      params['highlightColor'] = highlightColor;
    }

    if (defaultTextColor != null) {
      params['defaultTextColor'] = defaultTextColor;
    }

    if (imageTypeColor != null) {
      params['imageTypeColor'] = imageTypeColor;
    }

    if (readImageTypeColor != null) {
      params['readImageTypeColor'] = readImageTypeColor;
    }

    if (titleColor != null) {
      params['titleColor'] = titleColor;
    }

    if (readTitleColor != null) {
      params['readTitleColor'] = readTitleColor;
    }

    if (descriptionColor != null) {
      params['descriptionColor'] = descriptionColor;
    }

    if (readDescriptionColor != null) {
      params['readDescriptionColor'] = readDescriptionColor;
    }

    if (dateColor != null){ 
      params['dateColor'] = dateColor;
    }

    if (readDateColor != null) {
      params['readDateColor'] = readDateColor;
    }

    if (dividerColor != null) {
      params['dividerColor'] = dividerColor;
    }

    if (barBackgroundColor != null) {
      params['barBackgroundColor'] = barBackgroundColor;
    }

    if (barAccentColor != null) {
      params['barAccentColor'] = barAccentColor;
    }

    if (barTextColor != null) {
      params['barTextColor'] = barTextColor;
    }

    return params;
  }
}

/// Implementation of the Pushwoosh Inbox API for Flutter.
class PushwooshInbox {
  static const MethodChannel _channel = const MethodChannel('pushwoosh_inbox');

  /// Present Inbox UI
  static void presentInboxUI({PWInboxStyle? style}) {
    if (style != null) {
      _channel.invokeMethod("presentInboxUI", style._dictionaryRepresentation());
    } else {
      _channel.invokeMethod("presentInboxUI");
    }
  }

  static Future<int?> messagesWithNoActionPerformedCount() async {
    return await _channel.invokeMethod("messagesWithNoActionPerformedCount");
  }

  static Future<int?> unreadMessagesCount() async {
    return await _channel.invokeMethod("unreadMessagesCount");
  }

  static Future<int?> messagesCount() async {
    return await _channel.invokeMethod("messagesCount");
  }

  static Future<List<InboxMessage>> loadMessages() async {
    List<Object?> inboxMessages = await _channel.invokeMethod("loadMessages");
    List<InboxMessage> inboxMessageList = [];
    for (final Object? messageJson in inboxMessages) {
      InboxMessage inboxMessage = InboxMessage.fromJson(jsonDecode(messageJson.toString()));
      if (inboxMessage.code != "") {
        inboxMessageList.add(InboxMessage.fromJson(jsonDecode(messageJson.toString())));
      }
    }
    return inboxMessageList;
  }

  static Future<List<InboxMessage>> loadCachedMessages() async {
    List<Object?> inboxMessages = await _channel.invokeMethod("loadCachedMessages");
    List<InboxMessage> inboxMessageList = [];
    for (final Object? messageJson in inboxMessages) {
      inboxMessageList.add(InboxMessage.fromJson(jsonDecode(messageJson.toString())));
    }
    return inboxMessageList;
  }

  static void readMessage(String code) {
    _channel.invokeMethod("readMessage", {"code": code});
  }
  
  static void readMessages(List<String> codes) { 
    _channel.invokeMethod("readMessages", {"codes": codes});  
  }

  static void deleteMessage(String code) {
    _channel.invokeMethod("deleteMessage", {"code": code});
  }

  static void deleteMessages(List<String> codes) {
    _channel.invokeMethod("deleteMessages", {"codes": codes});
  }
  
  static void performAction(String code) {
    _channel.invokeMethod("performAction", {"code": code});
  }
}

class InboxMessage {
  final String code;
  final String? title;
  final String? imageUrl;
  final String? message;
  final String? sendDate;
  final int? messageType;
  final String? bannerUrl;
  final Map<String,dynamic>? customData;
  final Map<String,dynamic>? actionParams;

  bool? isRead;
  bool? isActionPerformed;

  InboxMessage(this.code, this.title, this.imageUrl, this.message, this.sendDate, this.messageType, this.bannerUrl, this.isRead, this.actionParams, this.isActionPerformed, this.customData);

  InboxMessage.fromJson(Map<String,dynamic> json)
    : code = json['code'] != null ? json['code'] : "",
      title = json['title'],
      imageUrl = json['imageUrl'],
      message = json['message'],
      sendDate = json['sendDate'],
      messageType = json['messageType'],
      bannerUrl = json['bannerUrl'],
      isRead = json['isRead'],
      actionParams = json['actionParams'] != null ? json['actionParams'] is String ? jsonDecode(json['actionParams']) : json['actionParams'] : null,

      isActionPerformed = json['isActionPerformed'],
      customData = json['customData'] != null ? jsonDecode(json['customData']) : null;
}