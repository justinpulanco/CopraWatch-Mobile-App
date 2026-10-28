import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MjpegPreview extends StatefulWidget {
  final String url;
  final Map<String, String>? headers;
  final BoxFit fit;
  final WidgetBuilder? errorBuilder;

  const MjpegPreview({
    super.key,
    required this.url,
    this.headers,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  @override
  State<MjpegPreview> createState() => _MjpegPreviewState();
}

class _MjpegPreviewState extends State<MjpegPreview> {
  http.Client? _client;
  StreamSubscription<List<int>>? _subscription;
  Uint8List? _frame;
  Object? _error;
  final List<int> _buffer = [];
  int _connectionGeneration = 0;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void didUpdateWidget(covariant MjpegPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.headers.toString() != widget.headers.toString()) {
      _connectionGeneration++;
      _subscription?.cancel();
      _client?.close();
      _buffer.clear();
      _frame = null;
      _error = null;
      _connect();
    }
  }

  Future<void> _connect() async {
    final generation = ++_connectionGeneration;
    while (mounted && generation == _connectionGeneration) {
      final client = http.Client();
      _client = client;
      try {
        final request = http.Request('GET', Uri.parse(widget.url));
        if (widget.headers != null) {
          request.headers.addAll(widget.headers!);
        }
        final response = await client.send(request);
        if (response.statusCode != 200) {
          throw Exception('Camera preview returned ${response.statusCode}');
        }

        final streamEnded = Completer<void>();
        void finishStream() {
          if (!streamEnded.isCompleted) streamEnded.complete();
        }

        _subscription = response.stream.listen(
          _readChunk,
          onError: (Object error) {
            if (mounted && generation == _connectionGeneration) {
              setState(() => _error = error);
            }
            finishStream();
          },
          onDone: finishStream,
          cancelOnError: true,
        );
        await streamEnded.future;
        if (mounted && generation == _connectionGeneration) {
          setState(() => _error = Exception('Camera preview disconnected'));
        }
      } catch (error) {
        if (mounted && generation == _connectionGeneration) {
          setState(() => _error = error);
        }
      } finally {
        await _subscription?.cancel();
        _subscription = null;
        client.close();
        if (identical(_client, client)) _client = null;
      }

      if (mounted && generation == _connectionGeneration) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
  }

  void _readChunk(List<int> chunk) {
    _buffer.addAll(chunk);
    while (true) {
      final start = _findMarker(0xFF, 0xD8);
      if (start < 0) {
        if (_buffer.length > 2) _buffer.removeRange(0, _buffer.length - 2);
        return;
      }

      final end = _findMarker(0xFF, 0xD9, start + 2);
      if (end < 0) {
        if (start > 0) _buffer.removeRange(0, start);
        return;
      }

      final frame = Uint8List.fromList(_buffer.sublist(start, end + 2));
      _buffer.removeRange(0, end + 2);
      if (mounted) {
        setState(() {
          _frame = frame;
          _error = null;
        });
      }
    }
  }

  int _findMarker(int first, int second, [int offset = 0]) {
    for (var index = offset; index < _buffer.length - 1; index++) {
      if (_buffer[index] == first && _buffer[index + 1] == second) return index;
    }
    return -1;
  }

  @override
  void dispose() {
    _connectionGeneration++;
    _subscription?.cancel();
    _client?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_frame != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(_frame!, fit: widget.fit, gaplessPlayback: true),
          if (_error != null)
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Reconnecting to camera preview…',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
        ],
      );
    }
    if (_error != null && widget.errorBuilder != null) {
      return widget.errorBuilder!(context);
    }
    if (_error != null) {
      return const Center(child: Text('Camera preview unavailable'));
    }
    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }
}
