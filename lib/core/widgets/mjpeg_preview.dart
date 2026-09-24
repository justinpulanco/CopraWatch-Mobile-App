import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MjpegPreview extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final WidgetBuilder? errorBuilder;

  const MjpegPreview({
    super.key,
    required this.url,
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

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    try {
      _client = http.Client();
      final request = http.Request('GET', Uri.parse(widget.url));
      final response = await _client!.send(request);
      if (response.statusCode != 200) {
        throw Exception('Camera stream returned ${response.statusCode}');
      }

      _subscription = response.stream.listen(
        _readChunk,
        onError: (Object error) {
          if (mounted) setState(() => _error = error);
        },
        onDone: () {
          if (mounted && _frame == null) {
            setState(() => _error = Exception('Camera stream ended'));
          }
        },
        cancelOnError: true,
      );
    } catch (error) {
      if (mounted) setState(() => _error = error);
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
    _subscription?.cancel();
    _client?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_frame != null) {
      return Image.memory(_frame!, fit: widget.fit, gaplessPlayback: true);
    }
    if (_error != null && widget.errorBuilder != null) {
      return widget.errorBuilder!(context);
    }
    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }
}
