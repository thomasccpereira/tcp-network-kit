// swift-tools-version: 6.1

import PackageDescription

let package = Package(
   name: "NetworkKit",
   platforms: [.iOS(.v18)],
   products: [
      .library(
         name: "NetworkKit",
         targets: ["NetworkKit"]),
   ],
   dependencies: [
      .package(url: "https://github.com/thomasccpereira/tcp-core-resources", from: "1.2.0"),
   ],
   targets: [
      .target(
         name: "NetworkKit",
         dependencies: [
            .product(name: "CoreResources", package: "tcp-core-resources"),
         ],
         resources: [
            .process("Resources/Localizable.xcstrings")
         ]
      ),
      .testTarget(
         name: "NetworkKitTests",
         dependencies: ["NetworkKit"],
         resources: [
            .process("Resources/Localizable.xcstrings")
         ]
      ),
   ]
)
