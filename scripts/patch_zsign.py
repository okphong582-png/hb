import os
import shutil

print("Running scripts/patch_zsign.py...")

zsign_dir = "Zsign"
if not os.path.exists(zsign_dir):
    print("Zsign directory does not exist yet. Creating...")
    os.makedirs(zsign_dir, exist_ok=True)

# 1. License file
lic_path = os.path.join(zsign_dir, "LICENSE_LC")
if not os.path.exists(lic_path):
    with open(lic_path, "w", encoding="utf-8") as f:
        f.write("MIT License\n")

src_dir = os.path.join(zsign_dir, "src")
inc_dir = os.path.join(src_dir, "include")
swift_dir = os.path.join(zsign_dir, "swift")
os.makedirs(inc_dir, exist_ok=True)

# 2. Copy and fix zsign.mm into src/
zsign_mm_src = os.path.join(swift_dir, "zsign.mm")
zsign_mm_dst = os.path.join(src_dir, "zsign.mm")
if os.path.exists(zsign_mm_src):
    with open(zsign_mm_src, "r", encoding="utf-8", errors="ignore") as f:
        zmm = f.read()
    # Fix block signature if needed: void(^completionHandler)(BOOL success, NSError *error) -> void(^completionHandler)(BOOL success)
    zmm = zmm.replace(
        "void(^completionHandler)(BOOL success, NSError *error)",
        "void(^completionHandler)(BOOL success)"
    )
    # Ensure completionHandler call is safe
    zmm = zmm.replace(
        "\tcompletionHandler(bRet);",
        "\tif (completionHandler) {\n\t\tcompletionHandler(bRet);\n\t}"
    )
    # Fix SignFolder 11-arguments signature: add missing arrDisDylibFiles
    zmm = zmm.replace(
        "bundle.SignFolder(&zsa, strFolder, strBundleId, strBundleVersion, strDisplayName, arrDylibFiles, bForce, bWeakInject, bEnableCache, excludeprovion);",
        "bundle.SignFolder(&zsa, strFolder, strBundleId, strBundleVersion, strDisplayName, arrDylibFiles, arrDisDylibFiles, bForce, bWeakInject, bEnableCache, excludeprovion);"
    )
    with open(zsign_mm_dst, "w", encoding="utf-8") as f:
        f.write(zmm)
    print("Patched and copied zsign.mm to src/zsign.mm")

# 3. Copy utils.mm into src/
utils_mm_src = os.path.join(swift_dir, "utils.mm")
utils_mm_dst = os.path.join(src_dir, "utils.mm")
if os.path.exists(utils_mm_src):
    shutil.copyfile(utils_mm_src, utils_mm_dst)
    print("Copied utils.mm to src/utils.mm")

# 4. Copy headers zsign.hpp & utils.hpp into src/ and src/include/
for h in ["zsign.hpp", "utils.hpp"]:
    h_src = os.path.join(swift_dir, h)
    if os.path.exists(h_src):
        with open(h_src, "r", encoding="utf-8", errors="ignore") as f:
            h_content = f.read()
        for target_folder in [src_dir, inc_dir]:
            h_dst = os.path.join(target_folder, h)
            with open(h_dst, "w", encoding="utf-8") as f:
                f.write(h_content)
        print(f"Copied {h} to src/ and src/include/")

# 5. Fix ZSign.h in src/include/
zsign_h = os.path.join(inc_dir, "ZSign.h")
zsign_h_content = """//
//  ZSign.h
//

#ifndef ZSign_h
#define ZSign_h

#include "zsign.hpp"
#include "utils.hpp"

#endif /* ZSign_h */
"""
with open(zsign_h, "w", encoding="utf-8") as f:
    f.write(zsign_h_content)
print("Updated src/include/ZSign.h")

# 6. Patch Package.swift
pkg_file = os.path.join(zsign_dir, "Package.swift")
if os.path.exists(pkg_file):
    new_package_swift = """// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "Zsign",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_15),
        .tvOS(.v12),
        .watchOS(.v8),
        .custom("xros", versionString: "1.3")
    ],
    products: [
        .library(
            name: "zsignc",
            targets: ["ZsignC"]
        ),
        .library(
            name: "ZsignC",
            targets: ["ZsignC"]
        ),
        .library(
            name: "Zsign",
            targets: ["Zsign", "ZsignC"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/OpenSSL", from: "3.3.3001")
    ],
    targets: [
        .target(
            name: "ZsignC",
            dependencies: [
                .product(name: "OpenSSL", package: "OpenSSL")
            ],
            path: "src",
            exclude: [
                "common/archive.cpp",
                "zsign.cpp"
            ],
            sources: [
                "archo.cpp",
                "bundle.cpp",
                "macho.cpp",
                "openssl.cpp",
                "utils.mm",
                "signing.cpp",
                "zsign.mm",
                "common/base64.cpp",
                "common/fs.cpp",
                "common/json.cpp",
                "common/log.cpp",
                "common/sha.cpp",
                "common/timer.cpp",
                "common/util.cpp"
            ],
            publicHeadersPath: "include",
            cxxSettings: [
                .headerSearchPath("."),
                .headerSearchPath("common"),
                .headerSearchPath("include"),
                .unsafeFlags(["-std=c++17"])
            ],
            linkerSettings: [
                .linkedFramework("OpenSSL"),
            ]
        ),
        .target(
            name: "Zsign",
            dependencies: [
                "ZsignC"
            ],
            path: "swift",
            sources: [
                "zsign.swift"
            ]
        )
    ]
)
"""
    with open(pkg_file, "w", encoding="utf-8") as f:
        f.write(new_package_swift)
    print("Rewrote Zsign/Package.swift with in-tree sources for ZsignC.")

print("scripts/patch_zsign.py completed successfully.")
