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
    .package(url: "https://github.com/geekaurora/CZDispatchQueue.git", from: "2.1.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
    .target(
      name: "CZOperationQueue",
      dependencies: ["CZUtils", "CZDispatchQueue"]),
    .testTarget(
      name: "CZOperationQueueTests",
      dependencies: ["CZOperationQueue"]),
  ]
)
