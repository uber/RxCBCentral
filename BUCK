load("//core:defs.bzl", "uber_apple_library", "uber_apple_test", "uber_xcode_workspace_config")

uber_apple_library(
    name = "RxCentralBLE",
    srcs = glob([
        "RxCentralBLE/**/*.swift",
    ]),
    extra_xcode_files = [
        "README.md",
    ],
    system_frameworks = [
        "Foundation",
    ],
    tests = [
        ":RxCentralBLETests",
    ],
    visibility = [
        "//apps/carbon/...",
    ],
    deps = [
        "//libraries/foundation/PresidioFoundation:PresidioFoundation",
        "//vendor/rxoptional:RxOptional",
        "//vendor/rxswift:RxSwift",
        "//vendor/swift-concurrency:Concurrency",
    ],
)

uber_apple_test(
    name = "RxCentralBLETests",
    srcs = glob([
        "RxCentralBLETests/**/*.swift",
    ]),
    info_plist = "RxCentralBLETests/Info.plist",
    system_frameworks = [
        "Foundation",
        "UIKit",
    ],
    visibility = [
        "//apps/carbon/...",
    ],
    deps = [
        "//libraries/foundation/Presidio:Presidio",
        "//libraries/foundation/PresidioFoundation:PresidioFoundation",
        "//libraries/foundation/PresidioUtilities:PresidioUtilities",
        "//libraries/foundation/RxCentralBLE:RxCentralBLE",
        "//libraries/foundation/TestCase:TestCase",
        "//vendor/rxoptional:RxOptional",
        "//vendor/rxswift:RxSwift",
        "//vendor/swift-concurrency:Concurrency",
    ],
)

uber_xcode_workspace_config(
    name = "RxCentralBLEScheme",
    extra_tests = [
        ":RxCentralBLETests",
    ],
    src_target = ":RxCentralBLE",
    visibility = [
        "//apps/carbon/...",
    ],
)
