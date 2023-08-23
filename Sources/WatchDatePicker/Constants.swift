#if os(watchOS)

import SwiftUI
import WatchKit

let isTakingScreenshots = ProcessInfo.processInfo.environment["WDP_SCREENSHOTS"] == "1"

enum WatchDeviceSize: Double {
  case _40mm = 162
  case _41mm = 176
  case _44mm = 184
  case _45mm = 198
  case _49mm = 205

  static var current: Self {
    .init(rawValue: WKInterfaceDevice.current().screenBounds.width) ?? ._45mm
  }
}

extension CGFloat {
  static var selectionIndicatorRadius: Self {
    switch WatchDeviceSize.current {
    case ._45mm, ._49mm: return 2.75
    default: return 2.25
    }
  }
  
  static var pickerCornerRadius: Self {
    switch WatchDeviceSize.current {
    case ._41mm, ._45mm, ._49mm: return 15
    default: return 8.5
    }
  }

  static var pickerFontSize: Self {
    switch WatchDeviceSize.current {
    case ._40mm: return 21
    default: return 23
    }
  }

  static var pickerLabelMinimumScaleFactor: Self {
    switch WatchDeviceSize.current {
    case ._41mm, ._45mm, ._49mm: return 0.8
    default: return 1
    }
  }
}

extension CGSize {
  static var heavyMarkSize: Self {
    switch WatchDeviceSize.current {
    case ._45mm, ._49mm: return CGSize(width: 2, height: 2.5)
    default: return CGSize(width: 1.5, height: 2.5)
    }
  }

  static var markSize: Self {
    switch WatchDeviceSize.current {
    case ._45mm, ._49mm: return CGSize(width: 1.75, height: 7.5)
    default: return CGSize(width: 1.25, height: 6.5)
    }
  }
}

extension Color {
  static let timeComponentButtonBorder = Color(white: 0.298)
}

#endif
