##!/bin/bash
#set -e
#
#cd rust_tantivy
#
#echo " Building for macOS..."
#cargo build --release
#
#echo " Building for Android..."
#if command -v cargo-ndk &> /dev/null; then
#    cargo ndk -t arm64-v8a -t armeabi-v7a -o ../android/app/src/main/jniLibs build --release
#else
#    echo "⚠️  Skipping Android (cargo-ndk not installed)"
#fi
#
#echo " Building for iOS..."
#if rustup target list | grep -q "aarch64-apple-ios (installed)"; then
#    cargo build --release --target aarch64-apple-ios
#else
#    echo "⚠️  Skipping iOS (target not installed)"
#fi
#
#echo "✅ Build complete!"


#!/bin/bash
set -e

cd rust_tantivy

echo "🔧 Building for macOS..."
cargo build --release

echo "🔧 Building for Android..."
if command -v cargo-ndk &> /dev/null; then
    cargo ndk -t arm64-v8a -t armeabi-v7a -o ../android/app/src/main/jniLibs build --release
else
    echo "⚠️  Skipping Android (cargo-ndk not installed)"
fi

echo "🔧 Building for iOS..."
if rustup target list | grep -q "aarch64-apple-ios (installed)"; then
    # iOS 배포 타겟 설정
    export IPHONEOS_DEPLOYMENT_TARGET=12.0

    # iOS 실기기용 빌드
    cargo build --release --target aarch64-apple-ios

    # iOS 시뮬레이터용 빌드 (선택사항)
    if rustup target list | grep -q "aarch64-apple-ios-sim (installed)"; then
        cargo build --release --target aarch64-apple-ios-sim
    fi
else
    echo "⚠️  Skipping iOS (target not installed)"
fi

echo "✅ Build complete!"