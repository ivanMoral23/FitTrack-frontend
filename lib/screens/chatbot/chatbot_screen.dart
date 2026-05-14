import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../globals/global_variables.dart';
import '../../utils/app_colors.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final AuthService _authService = AuthService();
  http.Client? _client;
  bool _isLoading = false;

  static const _suggestions = [
    '¿Qué ejercicios para pecho sin máquinas?',
    'Dame una rutina de 3 días',
    '¿Cómo mejorar mi recuperación?',
    '¿Cuánta proteína necesito?',
    'Plan de nutrición para ganar músculo',
  ];

  void _stopGeneration() {
    _client?.close();
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _client?.close();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _sendMessage(String userMessage) async {
    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
      _messages.add({'role': 'assistant', 'content': ''});
      _isLoading = true;
    });
    _scrollToBottom();

    _client = http.Client();
    final token = await _authService.getToken();

    final request = http.Request('POST', Uri.parse('$baseUrl/chat'));
    request.headers['Content-Type'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.body = jsonEncode({
      'model': 'llama3.1:8b',
      'prompt': userMessage,
      'stream': true,
    });

    try {
      final streamedResponse = await _client!.send(request);
      final stream = streamedResponse.stream.transform(utf8.decoder);

      await for (final chunk in stream) {
        for (final line in chunk.split('\n')) {
          if (line.trim().isEmpty) continue;
          try {
            final data = jsonDecode(line);
            final tok  = data['response'] as String? ?? '';
            final done = data['done']     as bool?   ?? false;
            setState(() => _messages.last['content'] = _messages.last['content']! + tok);
            _scrollToBottom();
            if (done) break;
          } catch (_) {}
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        final msg = e.toString();
        if (msg.contains('Request aborted') || msg.contains('Connection closed')) {
          _messages.last['content'] = '${_messages.last['content']!}\n\n[Generación detenida]';
        } else {
          _messages.last['content'] = 'Error de conexión. Por favor, revisa tu red.';
        }
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Asistente IA', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                Text('FitTrack AI', style: GoogleFonts.inter(fontSize: 11, color: colors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty ? _buildEmptyState() : _buildMessageList(),
          ),
          if (_isLoading)
            LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.primary,
              backgroundColor: AppColors.primaryLight,
            ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
            child: const Icon(Icons.psychology_rounded, color: AppColors.primary, size: 40),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Hola! Soy tu asistente de fitness.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'Puedo ayudarte con rutinas, nutricion, recuperacion y mucho mas. Prueba alguna de estas preguntas:',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13, color: colors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 24),
        ..._suggestions.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () { if (!_isLoading) _sendMessage(s); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primaryLight),
                boxShadow: colors.cardShadow,
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(s, style: GoogleFonts.inter(fontSize: 13, color: colors.textPrimary))),
                  Icon(Icons.chevron_right_rounded, size: 18, color: colors.textMuted),
                ],
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length,
      itemBuilder: (context, i) {
        final msg    = _messages[i];
        final isUser = msg['role'] == 'user';
        return _ChatBubble(
          message: msg['content']!,
          isUser: isUser,
          isStreaming: !isUser && i == _messages.length - 1 && _isLoading,
        );
      },
    );
  }

  Widget _buildInputBar() {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (v) {
                final text = v.trim();
                if (text.isNotEmpty && !_isLoading) { _controller.clear(); _sendMessage(text); }
              },
              style: GoogleFonts.inter(fontSize: 14, color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Escribe tu pregunta...',
                hintStyle: GoogleFonts.inter(color: colors.textMuted, fontSize: 14),
                filled: true,
                fillColor: colors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isLoading
                ? _stopGeneration
                : () {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) { _controller.clear(); _sendMessage(text); }
                  },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isLoading ? AppColors.error : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isLoading ? Icons.stop_rounded : Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat bubble
// ─────────────────────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.isUser, this.isStreaming = false});
  final String message;
  final bool isUser;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 16),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : colors.surface,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(18),
                  topRight:    const Radius.circular(18),
                  bottomLeft:  Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4  : 18),
                ),
                boxShadow: colors.cardShadow,
              ),
              child: isStreaming && message.isEmpty
                  ? _TypingIndicator()
                  : Text(
                      message,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.5,
                        color: isUser ? Colors.white : colors.textPrimary,
                      ),
                    ),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color = context.colors.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => Padding(
        padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
        child: Container(
          width: 7, height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      )),
    );
  }
}
