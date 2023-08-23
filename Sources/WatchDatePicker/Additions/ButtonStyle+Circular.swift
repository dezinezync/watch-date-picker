#if os(watchOS)

import SwiftUI

private let SUGGESTED_SIZE: CGFloat = 32.0

@available(macOS, unavailable)
@available(iOS, unavailable)
@available(tvOS, unavailable)
extension ButtonStyle where Self == CircularButtonStyle {
  static func circular(_ color: Color = .gray) -> Self { .init(color: color) }
}

struct CircularButtonStyle: ButtonStyle {
  @State private var padding: CGFloat = 0.0
  var color: Color

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.title3.bold())
      .padding(padding)
      //.frame(width: .circularButtonDiameter, height: .circularButtonDiameter)
      .foregroundColor(color == .gray ? .primary : color)
      .background { Circle().fill(color.opacity(color == .gray ? 0.38 : 0.3)) }
      .scaleEffect(configuration.isPressed ? 0.9 : 1)
      .opacity(configuration.isPressed ? 0.5 : 1)
  }
}

extension ButtonStyle where Self == SmallCircularButtonStyle {
  static func smallCircular(_ color: Color) -> Self { .init(color: color) }
}

struct SmallCircularButtonStyle: ButtonStyle {
  var color: Color

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: .circularButtonFontSize * 0.66, weight: .medium))
      .frame(width: .circularButtonDiameter * 0.6, height: .circularButtonDiameter * 0.6)
      .foregroundColor(.white)
      .background { Circle().fill(color) }
      .scaleEffect(configuration.isPressed ? 0.9 : 1)
      .opacity(configuration.isPressed ? 0.5 : 1)
  }
}

#endif
