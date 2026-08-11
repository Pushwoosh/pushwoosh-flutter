/// Native in-app configs for local preview via `Pushwoosh.getInstance.presentInApp(config)`.
///
/// Ported value for value from the native Android demo (`InAppPresets.kt`) — texts, colors and
/// urls stay identical there and here, that is what makes the two screenshots comparable.
/// Images point at picsum.photos: without network the layout still shows, the pictures do not.
library;

const Map<String, dynamic> banner = <String, dynamic>{
  'displayType': 'banner',
  'inAppId': 'demo-banner',
  'banner': <String, dynamic>{
    'showClose': true,
    'position': 'top',
    'background': '#1E88E5FF',
    'image': 'https://picsum.photos/seed/pwbanner/160/160',
    'title': <String, dynamic>{'text': 'Flash Sale', 'color': '#FFFFFFFF'},
    'message': <String, dynamic>{
      'text': '50% off — today only',
      'color': '#E3F2FDFF',
    },
    'action': <String, dynamic>{'type': 'url', 'url': 'https://pushwoosh.com'},
    'autoDismiss': 6,
  },
};

const Map<String, dynamic> modal = <String, dynamic>{
  'displayType': 'modal',
  'inAppId': 'demo-modal',
  'modal': <String, dynamic>{
    'showClose': true,
    'dimBackground': true,
    'background': '#FFFFFFFF',
    'image': 'https://picsum.photos/seed/pwmodal/600/320',
    'title': <String, dynamic>{'text': 'Welcome aboard!', 'color': '#1A1A1AFF'},
    'message': <String, dynamic>{
      'text':
          'Thanks for installing the app. Enable notifications so you never miss an update.',
      'color': '#555555FF',
    },
    'buttons': <dynamic>[
      <String, dynamic>{
        'text': <String, dynamic>{'text': 'Enable', 'color': '#FFFFFFFF'},
        'background': '#1E88E5FF',
        'border': <String, dynamic>{'color': '#1E88E5FF', 'radius': 12},
        'action': <String, dynamic>{
          'type': 'url',
          'url': 'https://pushwoosh.com',
        },
      },
      <String, dynamic>{
        'text': <String, dynamic>{'text': 'Later', 'color': '#1E88E5FF'},
        'background': '#FFFFFFFF',
        'border': <String, dynamic>{'color': '#1E88E5FF', 'radius': 12},
        'action': <String, dynamic>{'type': 'close'},
      },
    ],
  },
};

const Map<String, dynamic> modalFloating = <String, dynamic>{
  'displayType': 'modal',
  'inAppId': 'demo-modal-floating',
  'modal': <String, dynamic>{
    'showClose': true,
    'dimBackground': false,
    'background': '#263238FF',
    'title': <String, dynamic>{'text': 'New message', 'color': '#FFFFFFFF'},
    'message': <String, dynamic>{
      'text': 'This card floats over your content instead of blocking it.',
      'color': '#B0BEC5FF',
    },
    'buttons': <dynamic>[
      <String, dynamic>{
        'text': <String, dynamic>{'text': 'Open', 'color': '#263238FF'},
        'background': '#FFD54FFF',
        'border': <String, dynamic>{'color': '#FFD54FFF', 'radius': 20},
        'action': <String, dynamic>{'type': 'close'},
      },
    ],
  },
};

const Map<String, dynamic> sheet = <String, dynamic>{
  'displayType': 'sheet',
  'inAppId': 'demo-sheet',
  'sheet': <String, dynamic>{
    'showClose': true,
    'dimBackground': true,
    'background': '#FFFFFFFF',
    'image': 'https://picsum.photos/seed/pwsheet/600/320',
    'title': <String, dynamic>{
      'text': 'Your quote is ready',
      'color': '#1A1A1AFF',
    },
    'message': <String, dynamic>{
      'text': 'Guaranteed buyout for your A110: \$68,500. Valid for 7 days.',
      'color': '#555555FF',
    },
    'buttons': <dynamic>[
      <String, dynamic>{
        'text': <String, dynamic>{
          'text': 'Get guaranteed quote',
          'color': '#FFFFFFFF',
        },
        'background': '#1E88E5FF',
        'border': <String, dynamic>{'color': '#1E88E5FF', 'radius': 12},
        'action': <String, dynamic>{
          'type': 'url',
          'url': 'https://pushwoosh.com',
        },
      },
      <String, dynamic>{
        'text': <String, dynamic>{'text': 'Not now', 'color': '#1E88E5FF'},
        'background': '#FFFFFFFF',
        'border': <String, dynamic>{'color': '#1E88E5FF', 'radius': 12},
        'action': <String, dynamic>{'type': 'close'},
      },
    ],
  },
};

/// `showClose` is off on purpose: swipe-down is the guaranteed dismiss path here.
const Map<String, dynamic> sheetFloating = <String, dynamic>{
  'displayType': 'sheet',
  'inAppId': 'demo-sheet-floating',
  'sheet': <String, dynamic>{
    'showClose': false,
    'dimBackground': false,
    'background': '#263238FF',
    'title': <String, dynamic>{'text': 'Trade-in offer', 'color': '#FFFFFFFF'},
    'message': <String, dynamic>{
      'text': 'Swipe down to dismiss — the app stays usable behind this sheet.',
      'color': '#B0BEC5FF',
    },
    'buttons': <dynamic>[
      <String, dynamic>{
        'text': <String, dynamic>{'text': 'Open', 'color': '#263238FF'},
        'background': '#FFD54FFF',
        'border': <String, dynamic>{'color': '#FFD54FFF', 'radius': 20},
        'action': <String, dynamic>{'type': 'close'},
      },
    ],
  },
};

const Map<String, dynamic> fullscreen = <String, dynamic>{
  'displayType': 'fullscreen',
  'inAppId': 'demo-fullscreen',
  'fullscreen': <String, dynamic>{
    'showClose': true,
    'cover': <String, dynamic>{
      'image': 'https://picsum.photos/seed/pwcover/900/1400',
      'background': '#1A1A1EFF',
    },
    'title': <String, dynamic>{'text': 'Unlock Premium', 'color': '#FFFFFFFF'},
    'message': <String, dynamic>{
      'text': 'Go ad-free and get exclusive content.',
      'color': '#ECEFF1FF',
    },
    'buttons': <dynamic>[
      <String, dynamic>{
        'text': <String, dynamic>{
          'text': 'Start free trial',
          'color': '#FFFFFFFF',
        },
        'background': '#43A047FF',
        'border': <String, dynamic>{'color': '#43A047FF', 'radius': 12},
        'action': <String, dynamic>{
          'type': 'url',
          'url': 'https://pushwoosh.com',
        },
      },
      <String, dynamic>{
        'text': <String, dynamic>{'text': 'No thanks', 'color': '#FFFFFFFF'},
        'background': '#00000000',
        'border': <String, dynamic>{'color': '#FFFFFF99', 'radius': 12},
        'action': <String, dynamic>{'type': 'close'},
      },
    ],
  },
};

/// The last slide is image-only on purpose: it shows the text scrim going out.
const Map<String, dynamic> carousel = <String, dynamic>{
  'displayType': 'carousel',
  'inAppId': 'demo-carousel',
  'carousel': <String, dynamic>{
    'showClose': true,
    'items': <dynamic>[
      <String, dynamic>{
        'image': 'https://picsum.photos/seed/pwc1/640/420',
        'title': <String, dynamic>{'text': 'Explore', 'color': '#FFFFFFFF'},
        'message': <String, dynamic>{
          'text': 'Discover new features',
          'color': '#FFFFFFFF',
        },
        'action': <String, dynamic>{
          'type': 'url',
          'url': 'https://pushwoosh.com/1',
        },
      },
      <String, dynamic>{
        'image': 'https://picsum.photos/seed/pwc2/640/420',
        'title': <String, dynamic>{'text': 'Connect', 'color': '#FFFFFFFF'},
        'message': <String, dynamic>{
          'text': 'Reach your audience',
          'color': '#FFFFFFFF',
        },
        'action': <String, dynamic>{
          'type': 'url',
          'url': 'https://pushwoosh.com/2',
        },
      },
      <String, dynamic>{
        'image': 'https://picsum.photos/seed/pwc3/640/420',
        'title': <String, dynamic>{'text': 'Grow', 'color': '#FFFFFFFF'},
        'message': <String, dynamic>{
          'text': 'Boost engagement',
          'color': '#FFFFFFFF',
        },
        'action': <String, dynamic>{
          'type': 'url',
          'url': 'https://pushwoosh.com/3',
        },
      },
      <String, dynamic>{'image': 'https://picsum.photos/seed/pwc4/640/420'},
    ],
  },
};

const Map<String, dynamic> stories = <String, dynamic>{
  'displayType': 'stories',
  'inAppId': 'demo-stories',
  'stories': <String, dynamic>{
    'showClose': true,
    'loop': false,
    'items': <dynamic>[
      <String, dynamic>{
        'image': 'https://picsum.photos/seed/pws1/800/1400',
        'title': <String, dynamic>{'text': 'Day 1', 'color': '#FFFFFFFF'},
        'message': <String, dynamic>{
          'text': 'Your journey begins',
          'color': '#FFFFFFFF',
        },
        'duration': 4,
        'buttons': <dynamic>[
          <String, dynamic>{
            'text': <String, dynamic>{'text': 'Next', 'color': '#FFFFFFFF'},
            'background': '#0F0F0FFF',
            'border': <String, dynamic>{'color': '#0F0F0FFF', 'radius': 26},
            'action': <String, dynamic>{'type': 'close'},
          },
        ],
      },
      <String, dynamic>{
        'image': 'https://picsum.photos/seed/pws2/800/1400',
        'title': <String, dynamic>{'text': 'Day 2', 'color': '#FFFFFFFF'},
        'message': <String, dynamic>{
          'text': 'Keep the streak going',
          'color': '#FFFFFFFF',
        },
        'duration': 4,
        'buttons': <dynamic>[],
      },
      <String, dynamic>{
        'image': 'https://picsum.photos/seed/pws3/800/1400',
        'title': <String, dynamic>{'text': 'Day 3', 'color': '#FFFFFFFF'},
        'message': <String, dynamic>{
          'text': 'You are a pro now',
          'color': '#FFFFFFFF',
        },
        'duration': 4,
        'buttons': <dynamic>[
          <String, dynamic>{
            'text': <String, dynamic>{
              'text': 'Get started',
              'color': '#FFFFFFFF',
            },
            'background': '#0F0F0FFF',
            'border': <String, dynamic>{'color': '#0F0F0FFF', 'radius': 26},
            'action': <String, dynamic>{
              'type': 'url',
              'url': 'https://pushwoosh.com',
            },
          },
        ],
      },
    ],
  },
};

const List<(String, Map<String, dynamic>)> all = <(String, Map<String, dynamic>)>[
  ('BANNER', banner),
  ('MODAL', modal),
  ('MODAL (FLOATING)', modalFloating),
  ('SHEET', sheet),
  ('SHEET (FLOATING)', sheetFloating),
  ('FULLSCREEN', fullscreen),
  ('CAROUSEL', carousel),
  ('STORIES', stories),
];
