import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:convert';
import 'package:ffi/ffi.dart';
import 'ffi.dart';

class TantivyFFI {
  late final SearchFFI _bindings;
  late final ffi.DynamicLibrary _dylib;

  TantivyFFI() {
    _dylib = _loadLibrary();
    _bindings = SearchFFI(_dylib);
  }

  /// 플랫폼에 맞는 라이브러리 로드
  ffi.DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) {
      return ffi.DynamicLibrary.open('librust_tantivy.so');
    } else if (Platform.isIOS) {
      return ffi.DynamicLibrary.process();
    } else if (Platform.isMacOS) {
      return ffi.DynamicLibrary.open('librust_tantivy.dylib');
    } else if (Platform.isLinux) {
      return ffi.DynamicLibrary.open('librust_tantivy.so');
    } else if (Platform.isWindows) {
      return ffi.DynamicLibrary.open('rust_tantivy.dll');
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// Tantivy 인덱스 초기화
  int init(String indexPath) {
    final pathPtr = indexPath.toNativeUtf8();
    try {
      final result = _bindings.tantivy_init(pathPtr.cast<ffi.Char>());
      if (result != 0) {
        final errorMsg = _getLastError();
        throw Exception('Failed to initialize Tantivy: $errorMsg (code: $result)');
      }
      return result;
    } finally {
      malloc.free(pathPtr);
    }
  }

  /// 문서 추가
  int addDocument(String text) {
    final textPtr = text.toNativeUtf8();
    try {
      final result = _bindings.tantivy_add_doc(textPtr.cast<ffi.Char>());
      if (result != 0) {
        final errorMsg = _getLastError();
        throw Exception('Failed to add document: $errorMsg (code: $result)');
      }
      return result;
    } finally {
      malloc.free(textPtr);
    }
  }

  /// 검색 수행
  List<Map<String, dynamic>> search(String query, {int topK = 10}) {
    final queryPtr = query.toNativeUtf8();
    try {
      final resultPtr = _bindings.tantivy_search(queryPtr.cast<ffi.Char>(), topK);

      if (resultPtr == ffi.nullptr) {
        final errorMsg = _getLastError();
        throw Exception('Failed to search: $errorMsg');
      }

      try {
        final jsonStr = resultPtr.cast<Utf8>().toDartString();
        final results = jsonDecode(jsonStr) as List;
        return results.map((e) => e as Map<String, dynamic>).toList();
      } finally {
        _bindings.tantivy_free_str(resultPtr);
      }
    } finally {
      malloc.free(queryPtr);
    }
  }

  /// 마지막 에러 메시지 가져오기
  String? _getLastError() {
    final errorPtr = _bindings.tantivy_last_error();
    if (errorPtr == ffi.nullptr) {
      return null;
    }

    try {
      return errorPtr.cast<Utf8>().toDartString();
    } finally {
      _bindings.tantivy_free_str(errorPtr);
    }
  }

  /// 리소스 정리
  void dispose() {
    // DynamicLibrary는 자동으로 정리됨
  }
}