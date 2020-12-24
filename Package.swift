// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
// swiftlint:disable all

import PackageDescription

let package = Package(
    name: "ForemWebView",
    defaultLocalization: "en",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "ForemWebView",
            targets: ["ForemWebView"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/Yummypets/YPImagePicker", .branch("spm")),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.4.0"),
        .package(url: "https://github.com/Alamofire/AlamofireImage.git", from: "4.1.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ForemWebView",
            dependencies: ["YPImagePicker", "Alamofire", "AlamofireImage"],
            path: "Sources"),
        .testTarget(
            name: "ForemWebViewTests",
            dependencies: ["ForemWebView"],
            path: "Tests"),
    ]
)
