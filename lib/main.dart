import 'package:flutter/material.dart';
import 'package:flutter_tantivy_native/tantivy_search.dart';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tantivy Search Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SearchPage(),
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late TantivyFFI _tantivy;
  bool _isInitialized = false;
  String _statusMessage = 'Initializing...';
  final TextEditingController _queryController = TextEditingController();
  final TextEditingController _addDocController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  String _benchmarkResult = '';
  bool _isBenchmarking = false;

  @override
  void initState() {
    super.initState();
    _initializeTantivy();
  }

  Future<void> _initializeTantivy() async {
    try {
      _tantivy = TantivyFFI();

      // 임시 디렉토리에 인덱스 저장
      final tempDir = await getTemporaryDirectory();
      final indexPath = '${tempDir.path}/tantivy_index1';

      // 디렉토리가 없으면 생성
      final indexDir = Directory(indexPath);
      if (!await indexDir.exists()) {
        await indexDir.create(recursive: true);
      }

      // Tantivy 초기화
      _tantivy.init(indexPath);

      // 샘플 문서 추가
      _tantivy.addDocument('Hello world! This is a test document.');
      _tantivy.addDocument('Flutter is awesome for building mobile apps.');
      _tantivy.addDocument('Rust is fast and safe programming language.');
      _tantivy.addDocument(
        'Tantivy is a full-text search library written in Rust.',
      );
      _tantivy.addDocument(
        'Machine learning and artificial intelligence are transforming technology.',
      );
      _tantivy.addDocument(
        'Flutter uses Dart programming language for cross-platform development.',
      );
      _tantivy.addDocument(
        'Full-text search enables fast and efficient information retrieval.',
      );
      _tantivy.addDocument(
        'Mobile app development requires careful consideration of user experience.',
      );
      _tantivy.addDocument(
        'Rust provides memory safety without garbage collection.',
      );
      _tantivy.addDocument(
        'Search engines use inverted indexes for quick document lookup.',
      );
      _tantivy.addDocument(
        'Flutter widgets make building beautiful UIs simple and intuitive.',
      );
      _tantivy.addDocument(
        'Programming languages evolve to meet modern development needs.',
      );
      _tantivy.addDocument(
        'Tantivy leverages Rust performance for blazing fast search operations.',
      );
      _tantivy.addDocument(
        'Cross-platform frameworks save development time and resources.',
      );
      _tantivy.addDocument(
        'Text analysis and tokenization are crucial for search quality.',
      );

      // 일본어 샘플 문서 추加
      _tantivy.addDocument('こんにちは世界！これはテスト文書です。');
      _tantivy.addDocument('Flutterはモバイルアプリ開発に最適なフレームワークです。');
      _tantivy.addDocument('Rustは高速で安全なプログラミング言語です。');
      _tantivy.addDocument('Tantivyは Rust で書かれた全文検索ライブラリです。');
      _tantivy.addDocument('機械学習と人工知能が技術を変革しています。');
      _tantivy.addDocument('Flutterはクロスプラットフォーム開発にDart言語を使用します。');
      _tantivy.addDocument('全文検索は高速で効率的な情報検索を可能にします。');
      _tantivy.addDocument('モバイルアプリ開発にはユーザー体験の慎重な考慮が必要です。');
      _tantivy.addDocument('Rustはガベージコレクションなしでメモリ安全性を提供します。');
      _tantivy.addDocument('検索エンジンは迅速な文書検索のために転置インデックスを使用します。');
      _tantivy.addDocument('Flutterウィジェットは美しいUIの構築をシンプルで直感的にします。');
      _tantivy.addDocument('プログラミング言語は現代の開発ニーズに対応するために進化しています。');
      _tantivy.addDocument('Tantivyは超高速検索操作のためにRustのパフォーマンスを活用します。');
      _tantivy.addDocument('クロスプラットフォームフレームワークは開発時間とリソースを節約します。');
      _tantivy.addDocument('テキスト分析とトークン化は検索品質にとって重要です。');
      _tantivy.addDocument('東京は日本の首都であり、世界最大の都市の一つです。');
      _tantivy.addDocument('桜は日本の春を象徴する美しい花です。');
      _tantivy.addDocument('寿司とラーメンは世界的に人気のある日本料理です。');

      setState(() {
        _isInitialized = true;
        _statusMessage = 'Ready! Index path: $indexPath';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _performSearch() async {
    if (!_isInitialized) return;

    try {
      final query = _queryController.text.trim();
      if (query.isEmpty) return;

      final results = _tantivy.search(query, topK: 10);

      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Search error: $e')));
    }
  }

  Future<void> _addDocument() async {
    if (!_isInitialized) return;

    try {
      final text = _addDocController.text.trim();
      if (text.isEmpty) return;

      _tantivy.addDocument(text);
      _addDocController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Add error: $e')));
    }
  }

  Future<void> _runBenchmark() async {
    if (!_isInitialized) return;

    final query = _queryController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a search query first')),
      );
      return;
    }

    setState(() {
      _isBenchmarking = true;
      _benchmarkResult = 'Running benchmark...';
    });

    try {
      const iterations = 100;
      final List<double> times = [];

      // Warm-up (첫 실행은 캐시 등의 영향으로 느릴 수 있음)
      for (int i = 0; i < 5; i++) {
        _tantivy.search(query, topK: 10);
      }

      // 실제 벤치마크 측정
      for (int i = 0; i < iterations; i++) {
        final stopwatch = Stopwatch()..start();
        _tantivy.search(query, topK: 10);
        stopwatch.stop();
        times.add(stopwatch.elapsedMicroseconds / 1000.0); // ms로 변환
      }

      // 통계 계산
      times.sort();
      final avg = times.reduce((a, b) => a + b) / times.length;
      final min = times.first;
      final max = times.last;
      final median = times[times.length ~/ 2];
      final p95 = times[(times.length * 0.95).toInt()];
      final p99 = times[(times.length * 0.99).toInt()];

      setState(() {
        _benchmarkResult =
            '''
Benchmark Results ($iterations iterations):
─────────────────────────────
Query: "$query"
Average:  ${avg.toStringAsFixed(3)} ms
Median:   ${median.toStringAsFixed(3)} ms
Min:      ${min.toStringAsFixed(3)} ms
Max:      ${max.toStringAsFixed(3)} ms
P95:      ${p95.toStringAsFixed(3)} ms
P99:      ${p99.toStringAsFixed(3)} ms
─────────────────────────────
QPS: ${(1000 / avg).toStringAsFixed(0)} queries/sec
''';
        _isBenchmarking = false;
      });
    } catch (e) {
      setState(() {
        _benchmarkResult = 'Benchmark error: $e';
        _isBenchmarking = false;
      });
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    _addDocController.dispose();
    if (_isInitialized) {
      _tantivy.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tantivy Search Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status
            Card(
              color: _isInitialized
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Add Document Section
            const Text(
              'Add Document:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addDocController,
                    decoration: const InputDecoration(
                      hintText: 'Enter document text...',
                      border: OutlineInputBorder(),
                    ),
                    enabled: _isInitialized,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isInitialized ? _addDocument : null,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search Section
            const Text(
              'Search:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    decoration: const InputDecoration(
                      hintText: 'Enter search query...',
                      border: OutlineInputBorder(),
                    ),
                    enabled: _isInitialized,
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isInitialized ? _performSearch : null,
                  child: const Text('Search'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isInitialized && !_isBenchmarking
                      ? _runBenchmark
                      : null,
                  icon: _isBenchmarking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.timer),
                  label: const Text('Benchmark'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (_benchmarkResult.isNotEmpty) ...[
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Benchmark Results',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () {
                                      setState(() {
                                        _benchmarkResult = '';
                                      });
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _benchmarkResult,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 16),

                    // Results
                    const Text(
                      'Results:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _searchResults.isEmpty
                        ? const Center(
                            child: Text('No results. Try searching!'),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final result = _searchResults[index];
                              return Card(
                                child: ListTile(
                                  title: Text(result['text'] ?? ''),
                                  subtitle: Text(
                                    'Score: ${result['score']?.toStringAsFixed(4)}',
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),

            // Benchmark Results
          ],
        ),
      ),
    );
  }
}
