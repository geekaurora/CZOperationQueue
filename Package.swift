// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "CZOperationQueue",
  platforms: [
    .iOS(.v11),
  ],
  products: [
    // Products define the executables and libraries produced by a package, and make them visible to other packages.
    .library(
      name: "CZOperationQueue",
      type: .dynamic,
      targets: ["CZOperationQueue"]),
  ],
  dependencies: [
    .package(url: "https://github.com/geekaurora/CZUtils.git", from: "3.7.0"),
    .package(url: "https://github.com/geekaurora/CZTestUtils.git", from: "1.1.2"),
  ],
  targets: [
    .target(
      name: "CZOperationQueue",
      dependencies: ["CZUtils"]),
    .testTarget(
      name: "CZOperationQueueTests",
      dependencies: ["CZOperationQueue", "CZUtils", "CZTestUtils"]),
  ]
)
