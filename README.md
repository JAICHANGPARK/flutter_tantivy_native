# flutter_tantivy_native
# Flutter Tantivy Native

🚀 고성능 전문 검색(Full-Text Search) 엔진을 Flutter 앱에 통합하세요!

Flutter Tantivy Native는 Rust로 작성된 초고속 검색 엔진 [Tantivy](https://github.com/tantivy-search/tantivy)를 Flutter에서 사용할 수 있도록 하는 FFI 기반 라이브러리입니다.

## ✨ 주요 기능

- ⚡ **초고속 검색**: Rust의 성능과 Tantivy의 최적화된 인덱싱
- 🌍 **다국어 지원**: 영어, 한국어, 일본어 등 다양한 언어 검색
- 📱 **크로스 플랫폼**: Android, iOS, Windows, macOS, Linux 지원
- 🔍 **전문 검색**: 토큰화, 역인덱스, BM25 랭킹 알고리즘
- 📊 **실시간 벤치마킹**: 검색 성능 측정 도구 내장
- 💾 **영구 저장**: 디스크 기반 인덱스 저장소
- 🛠️ **간단한 API**: 직관적이고 사용하기 쉬운 인터페이스

## 🎯 성능
Flutter app using Rust (Tantivy) via FFI

## Overview
This project integrates a Rust native library that wraps the Tantivy full-text search engine and exposes a small C ABI. Flutter uses ffigen to generate Dart bindings from the C header.

Rust crate path: `rust_tantivy`
Generated header path: `rust_tantivy/include/rust_tantivy.h`
Generated Dart bindings path: `lib/ffi/rust_tantivy.dart`

The minimal C API exports:
- `int tantivy_init(const char* index_dir)`
- `int tantivy_add_doc(const char* text)`
- `char* tantivy_search(const char* query, int top_k)` → JSON string array of `{score, text}`; must be freed via `tantivy_free_str`.
- `char* tantivy_last_error()` → last error message or NULL; must be freed via `tantivy_free_str`.
- `void tantivy_free_str(char* s)`

A simple manual example wrapper is provided at `lib/ffi/example_usage.dart`. For production, run ffigen to generate the bindings.

## Prerequisites
- Rust toolchain (stable) and Cargo
- cbindgen installed: `cargo install cbindgen`
- LLVM installed for ffigen (macOS: `brew install llvm`)
- Flutter SDK

## Build the Rust library
```
cd rust_tantivy
cargo build --release
```
Artifacts (by platform):
- macOS: `target/release/librust_tantivy.dylib`
- Linux/Android: `target/release/librust_tantivy.so`
- Windows: `target/release/rust_tantivy.dll`
- iOS: static `.a` (additional steps with cargo lipo or xcframework are needed)

## Generate the C header
```
cd rust_tantivy
mkdir -p include
cbindgen --config cbindgen.toml --crate rust_tantivy --output include/rust_tantivy.h
```

## Generate Dart bindings with ffigen
Update dependencies and run ffigen:
```
flutter pub get
flutter pub run ffigen
```
This will generate `lib/ffi/rust_tantivy.dart` from the header at `rust_tantivy/include/rust_tantivy.h`.

## Using from Flutter (manual example)
See `lib/ffi/example_usage.dart` for a minimal example of loading the library and calling functions. It expects the dynamic library to be discoverable:
- macOS: place/copy `librust_tantivy.dylib` next to the app binary or set DYLD_LIBRARY_PATH during development.
- Linux: `librust_tantivy.so` in LD_LIBRARY_PATH or next to the binary.
- Windows: `rust_tantivy.dll` next to the EXE.
- Android: bundle `librust_tantivy.so` under `android/app/src/main/jniLibs/<abi>/` (e.g., `arm64-v8a`, `armeabi-v7a`, `x86_64`).
- iOS: link the static library into the Xcode project or create an xcframework; then use `DynamicLibrary.process()`.

Example flow (pseudo):
```
final lib = RustTantivyFFI.open();
final rust = RustTantivyFFI(lib);
final dir = Directory.systemTemp.createTempSync('tantivy');
rust.init(dir.path);
rust.addDoc('hello world');
final res = rust.search('hello', topK: 5);
print(res);
```

## Notes
- All strings passed to or returned from Rust are UTF-8.
- Call `tantivy_free_str` for any pointer returned by `tantivy_search` and `tantivy_last_error` after converting it to Dart string.
- The provided API and packaging are intentionally minimal to keep this example simple.
