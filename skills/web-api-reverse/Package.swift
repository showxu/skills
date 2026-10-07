// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "web-api-reverse",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(
      name: "WebAPIReverseCore",
      targets: ["WebAPIReverseCore"]
    ),
    .executable(
      name: "web-api-reverse",
      targets: ["WebAPIReverseCLI"]
    ),
  ],
  targets: [
    .target(
      name: "WebAPIReverseCore",
      resources: [
        .copy("Resources")
      ]
    ),
    .executableTarget(
      name: "WebAPIReverseCLI",
      dependencies: ["WebAPIReverseCore"]
    ),
    .target(
      name: "WebAPIReverseProviderMiddlewareExample",
      path: "examples/ProviderMiddleware"
    ),
    .testTarget(
      name: "WebAPIReverseCoreTests",
      dependencies: [
        "WebAPIReverseCore",
        "WebAPIReverseProviderMiddlewareExample",
      ]
    ),
    .testTarget(
      name: "WebAPIReverseCLITests",
      dependencies: ["WebAPIReverseCLI"]
    ),
  ],
  swiftLanguageModes: [.v6]
)
