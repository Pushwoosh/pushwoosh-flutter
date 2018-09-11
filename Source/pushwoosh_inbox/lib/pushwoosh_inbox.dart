import 'dart:async';

import 'package:flutter/services.dart';

class PWInboxStyle {
  String dateFormat;

  Map<String, dynamic> dictionaryRepresentation() {
    Map<String, dynamic> params = Map();

    if (dateFormat != null) {
      params['dateFormat'] = dateFormat;
    }

    return params;
  }
}

// //! The default icon in the cell next to the message; if not specified, the app icon is used
// @property (nonatomic, readwrite) UIImage *defaultImageIcon;

// //! The default font
// @property (nonatomic, readwrite) UIFont *defaultFont;

// //! The default text color
// @property (nonatomic, readwrite) UIColor *defaultTextColor;

// //! The default background color
// @property (nonatomic, readwrite) UIColor *backgroundColor;

// //! The default selection color
// @property (nonatomic, readwrite) UIColor *selectionColor;

// //! The appearance of the unread messages mark
// @property (nonatomic, readwrite) UIImage *unreadImage;

// //! The image which is displayed if an error occurs and the list of inbox messages is empty
// @property (nonatomic, readwrite) UIImage *listErrorImage;

// //! The error text which is displayed when an error occurs; cannot be localized
// @property (nonatomic, readwrite) NSString *listErrorMessage;

// //! The image which is displayed if the list of inbox messages is empty
// @property (nonatomic, readwrite) UIImage *listEmptyImage;

// //! The text which is displayed if the list of inbox messages is empty; cannot be localized
// @property (nonatomic, readwrite) NSString *listEmptyMessage;

// //! The accent color
// @property (nonatomic, readwrite) UIColor *accentColor;

// //! The color of message titles
// @property (nonatomic, readwrite) UIColor *titleColor;

// //! The color of messages descriptions
// @property (nonatomic, readwrite) UIColor *descriptionColor;

// //! The color of message dates
// @property (nonatomic, readwrite) UIColor *dateColor;

// //! The color of the separator
// @property (nonatomic, readwrite) UIColor *separatorColor;

// //! The font of message titles
// @property (nonatomic, readwrite) UIFont *titleFont;

// //! The font of message descriptions
// @property (nonatomic, readwrite) UIFont *descriptionFont;

// //! The font of message dates
// @property (nonatomic, readwrite) UIFont *dateFont;

// //! The default bar color
// @property (nonatomic, readwrite) UIColor *barBackgroundColor;

// //! The default back button color
// @property(nonatomic, readwrite) UIColor *barAccentColor;

// //! The default bar accent color
// @property (nonatomic, readwrite) UIColor *barTextColor;

// //! The default bar title text
// @property (nonatomic, readwrite) NSString *barTitle;

/// Implementation of the Pushwoosh Inbox API for Flutter.
class PushwooshInbox {
  static const MethodChannel _channel = const MethodChannel('pushwoosh_inbox');


  /// Present Inbox UI
  static void presentInboxUI({PWInboxStyle style}) {
    if (style != null) {
      _channel.invokeMethod("presentInboxUI", style.dictionaryRepresentation());
    } else {
      _channel.invokeMethod("presentInboxUI");
    }
    
  }
}
