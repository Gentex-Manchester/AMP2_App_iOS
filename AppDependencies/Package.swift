// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "AppDependencies",
    // Matches the app's deployment target. A lower floor here would build, but
    // it would leave the wrapper claiming support the app itself no longer has.
    platforms: [.iOS(.v18)],
    products: [
        // Dynamic so a single copy is shared by the app and the unit-test target
        // (a static product linked into both would duplicate its object code and
        // fail the build). Because it is dynamic, the app target MUST embed &
        // code-sign AppDependencies.framework via an "Embed Frameworks" build
        // phase, otherwise dyld cannot find it on-device and the app aborts at
        // launch (SIGABRT / __abort_with_payload).
        .library(name: "AppDependencies", type: .dynamic, targets: ["AppDependencies"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/stephencelis/SQLite.swift.git",
            from: "0.16.0",
            traits: ["SQLCipher"]
        )
    ],
    targets: [
        .target(
            name: "AppDependencies",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift")
            ]
        )
    ]
)
