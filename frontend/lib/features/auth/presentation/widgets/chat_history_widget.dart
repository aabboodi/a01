import 'package:flutter/material.dart';
import 'package:frontend/features/auth/application/services/chat_service.dart';
import 'package:frontend/features/auth/presentation/screens/teacher_classroom_screen.dart'; // For ChatMessage

class ChatHistoryWidget extends StatefulWidget {
  final String classId;
  const ChatHistoryWidget({super.key, required this.classId});

  @override
  State<ChatHistoryWidget> createState() => _ChatHistoryWidgetState();
}

class _ChatHistoryWidgetState extends State<ChatHistoryWidget> {
  final ApiChatService _apiChatService = ApiChatService();
  Future<List<dynamic>>? _chatHistoryFuture;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  void _loadChatHistory() {
    setState(() {
      _chatHistoryFuture = _apiChatService.getChatHistory(widget.classId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _chatHistoryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final messages = snapshot.data ?? [];
        return ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            return ListTile(
              title: Text(msg['user']?['full_name'] ?? 'System'),
              subtitle: Text(msg['message']),
            );
          },
        );
      },
    );
  }
}
