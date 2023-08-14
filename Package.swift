// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "watch-date-picker",
  defaultLocalization: "en",
  platforms: [
    .watchOS(.v9),
  ],
  products: [
    .library(name: "WatchDatePicker", targets: ["WatchDatePicker"]),
  ],
  targets: [
    .target(name: "WatchDatePicker", dependencies: []),
  ]
)
