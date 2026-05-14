import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../globals/global_variables.dart';
import '../../services/auth_service.dart';

class ChatbotWidget extends StatefulWidget {
  const ChatbotWidget({super.key});

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final ScrollController _textScrollController = ScrollController();
  bool _isLoading = false;
  bool _cancelled = false;
  StreamSubscription? _streamSubscription;

  Future<void> _sendMessage(String userMessage) async {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _cancelled = false;
    setState(() {
      _messages.add({"role": "user", "content": userMessage});
      _messages.add({"role": "assistant", "content": ""});
      _isLoading = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });

    final request = http.Request(
      'POST',
      Uri.parse('$baseUrl/chat'),
    );
    request.headers['Content-Type'] = 'application/json';
    
    final token = await AuthService().getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.body = jsonEncode({
      "model": "llama3.1:8b",
      "prompt": userMessage,
      "stream": true,
    });

    try {
      final streamedResponse = await request.send();
      final stream = streamedResponse.stream.transform(utf8.decoder);

      _streamSubscription = stream.listen(
        (chunk) {
          if (_cancelled) return;
          for (final line in chunk.split('\n')) {
            if (line.trim().isEmpty) continue;
            try {
              final data = jsonDecode(line);
              final token = data['response'] as String? ?? '';
              final done = data['done'] as bool? ?? false;

              setState(() {
                _messages.last['content'] = _messages.last['content']! + token;
              });

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(
                    _scrollController.position.maxScrollExtent,
                  );
                }
              });

              if (done) {
                setState(() => _isLoading = false);
                return;
              }
            } catch (_) {}
          }
        },
        onDone: () {
          if (!_cancelled) setState(() => _isLoading = false);
        },
        onError: (e) {
          if (!_cancelled) {
            setState(() {
              _messages.last['content'] = "Error de conexión: $e";
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (!_cancelled) {
        setState(() {
          _messages.last['content'] = "Error de conexión: $e";
          _isLoading = false;
        });
      }
    }
  }

  void _stopGeneration() {
    _cancelled = true;
    _streamSubscription?.cancel();
    _streamSubscription = null;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ScrollbarTheme(
            data: ScrollbarThemeData(
              thickness: WidgetStateProperty.all(4),
              crossAxisMargin: 4,
            ),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['role'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.blue[700] : Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        msg['content']!.isEmpty && !isUser ? '...' : msg['content']!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(8),
            child: LinearProgressIndicator(),
          ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScrollbarTheme(
                  data: ScrollbarThemeData(
                    thickness: WidgetStateProperty.all(4),
                    crossAxisMargin: 4,
                  ),
                  child: Scrollbar(
                    controller: _textScrollController,
                    thumbVisibility: true,
                    child: TextField(
                      controller: _controller,
                      scrollController: _textScrollController,
                      minLines: 1,
                      maxLines: 7,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Escribe tu pregunta...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.fromLTRB(12, 12, 12, 4),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_isLoading)
                      Container(
                        margin: const EdgeInsets.only(right: 4, bottom: 4),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: IconButton(
                          iconSize: 14,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.stop_rounded, color: Colors.white),
                          onPressed: _stopGeneration,
                        ),
                      )
                    else
                      Container(
                        margin: const EdgeInsets.only(right: 4, bottom: 4),
                        width: 28,
                        height: 28,
                        child: IconButton(
                          iconSize: 14,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.send),
                          onPressed: () {
                            final text = _controller.text.trim();
                            if (text.isNotEmpty) {
                              _controller.clear();
                              _sendMessage(text);
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
