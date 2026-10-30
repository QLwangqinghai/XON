// swift-tools-version:5.4

import PackageDescription

let package = Package(
    name: "XON",
    platforms: [
        .iOS(.v12),
        .tvOS(.v12),
        .watchOS(.v5),
        .macOS(.v10_13)
    ],
    products: [
        .library(name: "XON", type: .dynamic, targets: ["XON"]),
    ],
    dependencies: [
        .package(name: "CX", path: "../CX"),
    ],
    targets: [
        .target(name: "XON", dependencies: [.product(name: "CX", package: "CX"),], path: "Sources/XON", exclude: [], sources: nil, publicHeadersPath: nil, cSettings: nil, cxxSettings: nil, swiftSettings: nil, linkerSettings: nil),
    ],
    cLanguageStandard: .c11,
    cxxLanguageStandard: .cxx11
)

