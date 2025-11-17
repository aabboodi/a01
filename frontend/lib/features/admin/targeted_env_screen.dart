import 'package:flutter/material.dart';
import 'package:frontend/core/services/follower_service.dart';
import 'package:frontend/core/services/messaging_service.dart';

class TargetedEnvScreen extends StatelessWidget {
  const TargetedEnvScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('البيئة المستهدفة'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.group), text: 'إدارة المتابعين'),
              Tab(icon: Icon(Icons.message), text: 'إرسال رسالة'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            FollowersManagementTab(),
            SendMessageTab(),
          ],
        ),
      ),
    );
  }
}

// Followers Management Tab
class FollowersManagementTab extends StatefulWidget {
  const FollowersManagementTab({super.key});
  @override
  State<FollowersManagementTab> createState() => _FollowersManagementTabState();
}

class _FollowersManagementTabState extends State<FollowersManagementTab> {
  final FollowerService _followerService = FollowerService();
  List<dynamic> _followers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    setState(() => _isLoading = true);
    try {
      final followers = await _followerService.getFollowers();
      setState(() {
        _followers = followers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteFollower(String followerId) async {
    try {
      await _followerService.deleteFollower(followerId);
      _loadFollowers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  Future<void> _showAddFollowerDialog() async {
    // ... dialog logic ...
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildFollowerTable(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFollowerDialog,
        tooltip: 'إضافة متابع',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFollowerTable() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('خطأ: $_error'));
    if (_followers.isEmpty) return const Center(child: Text('لا يوجد متابعين.'));
    return DataTable(
      columns: const [
        DataColumn(label: Text('الاسم')),
        DataColumn(label: Text('الهاتف')),
        DataColumn(label: Text('إجراء')),
      ],
      rows: _followers.map((f) => DataRow(cells: [
        DataCell(Text(f['full_name'])),
        DataCell(Text(f['phone_number'])),
        DataCell(IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteFollower(f['follower_id']),
        )),
      ])).toList(),
    );
  }
}

// Send Message Tab
class SendMessageTab extends StatefulWidget {
  const SendMessageTab({super.key});
  @override
  State<SendMessageTab> createState() => _SendMessageTabState();
}

class _SendMessageTabState extends State<SendMessageTab> {
  final MessagingService _messagingService = MessagingService();
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;
    setState(() => _isSending = true);
    try {
      final result = await _messagingService.sendBulkMessage(_messageController.text);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم الإرسال إلى ${result['recipients']} مستلم.'), backgroundColor: Colors.green));
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _messageController,
            maxLines: 8,
            decoration: const InputDecoration(hintText: 'اكتب رسالتك...', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          _isSending
              ? const CircularProgressIndicator()
              : ElevatedButton.icon(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  label: const Text('إرسال للجميع'),
                ),
        ],
      ),
    );
  }
}
