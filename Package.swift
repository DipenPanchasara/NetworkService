// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

private let packageName: String = "NetworkService"

let package = Package(
  name: packageName,
  platforms: [
    .iOS(.v16),
    .macOS(.v10_15)
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .executable(
      name: packageName,
      targets: [packageName]
    ),
  ],
  targets: [
    .target(name: "NetworkService"),
    .testTarget(
      name: "NetworkServiceTests",
      dependencies: [.byName(name: packageName, condition: nil)]
    )
  ]
)
