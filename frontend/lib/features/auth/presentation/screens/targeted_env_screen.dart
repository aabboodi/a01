import 'package:flutter/material.dart';
import 'package:frontend/features/auth/application/services/follower_service.dart';
import 'package:frontend/features/auth/application/services/messaging_service.dart';

class TargetedEnvScreen extends StatefulWidget {
  const TargetedEnvScreen({super.key});

  @override
  State<TargetedEnvScreen> createState() => _TargetedEnvScreenState();
}

class _TargetedEnvScreenState extends State<TargetedEnvScreen> {
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

// MARK: - Followers Management Tab

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
    setState(() {
      _isLoading = true;
      _error = null;
    });
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showAddFollowerDialog() async {
    final formKey = GlobalKey<FormState>();
    final fullNameController = TextEditingController();
    final phoneController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('إضافة متابع جديد'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: fullNameController,
                  decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                  validator: (value) => value!.isEmpty ? 'الحقل مطلوب' : null,
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                  validator: (value) => value!.isEmpty ? 'الحقل مطلوب' : null,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('إضافة'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await _followerService.createFollower(
                      fullNameController.text,
                      phoneController.text,
                    );
                    Navigator.of(context).pop();
                    _loadFollowers();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('خطأ: $_error'));
    }
    if (_followers.isEmpty) {
      return const Center(child: Text('لا يوجد متابعين لعرضهم.'));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('الاسم الكامل')),
          DataColumn(label: Text('رقم الهاتف')),
          DataColumn(label: Text('إجراء')),
        ],
        rows: _followers.map((follower) {
          return DataRow(cells: [
            DataCell(Text(follower['full_name'])),
            DataCell(Text(follower['phone_number'])),
            DataCell(IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteFollower(follower['follower_id']),
            )),
          ]);
        }).toList(),
      ),
    );
  }
}

// MARK: - Send Message Tab

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
    if (_messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن إرسال رسالة فارغة.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final result = await _messagingService.sendBulkMessage(_messageController.text);
      final recipients = result['recipients'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إرسال الرسالة بنجاح إلى $recipients مستلم.'), backgroundColor: Colors.green),
      );
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'أرسل رسالة جماعية عبر WhatsApp إلى جميع الطلاب والمتابعين.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _messageController,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'اكتب رسالتك هنا...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isSending ? null : _sendMessage,
            icon: _isSending
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
            label: Text(_isSending ? 'جار الإرسال...' : 'إرسال الرسالة'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
