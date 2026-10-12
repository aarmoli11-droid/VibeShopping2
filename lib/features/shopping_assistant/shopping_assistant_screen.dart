import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/vibe_constants.dart';
import 'shopping_assistant_provider.dart';

class ShoppingAssistantScreen extends StatefulWidget {
  const ShoppingAssistantScreen({super.key});

  @override
  State<ShoppingAssistantScreen> createState() =>
      _ShoppingAssistantScreenState();
}

class _ShoppingAssistantScreenState extends State<ShoppingAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    context.read<ShoppingAssistantProvider>().sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final assistant = context.watch<ShoppingAssistantProvider>();

    // Auto-scroll when messages change.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });

    return Scaffold(
      backgroundColor: VibeColors.backgroundWhite,
      appBar: AppBar(title: const Text('VibeShopping Assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              children: [
                for (final message in assistant.messages) _bubble(message),
                if (assistant.isLoading)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: VibeColors.mint),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildInput(assistant.isLoading),
        ],
      ),
    );
  }

  Widget _buildInput(bool isLoading) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _send(),
                textInputAction: TextInputAction.send,
                decoration:
                    const InputDecoration(hintText: 'Escribe tu mensaje…'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: isLoading ? null : _send,
              style: IconButton.styleFrom(
                backgroundColor: VibeColors.navy,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
                minimumSize: const Size(38, 38),
                maximumSize: const Size(38, 38),
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.arrow_upward, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(ShoppingAssistantMessage message) {
    final background = message.isUser
        ? VibeColors.navy
        : message.isError
            ? VibeColors.errorBackground
            : VibeColors.backgroundMint;

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
              color: message.isUser ? Colors.white : VibeColors.navy,
              fontSize: 15),
        ),
      ),
    );
  }
}
