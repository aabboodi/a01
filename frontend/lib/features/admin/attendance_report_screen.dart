import 'package:flutter/material.dart';
import 'package:frontend/features/auth/application/services/reports_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AttendanceReportScreen extends StatefulWidget {
  final String classId;
  const AttendanceReportScreen({super.key, required this.classId});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  final ReportsService _reportsService = ReportsService();
  Future<List<dynamic>>? _reportFuture;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  void _loadReport() {
    setState(() {
      _reportFuture = _reportsService.getAttendanceReport(widget.classId);
    });
  }

  Future<void> _downloadReport() async {
    final url = 'http://10.0.2.2:3000/reports/attendance/${widget.classId}/download';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadReport,
            tooltip: 'Download as Excel',
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final report = snapshot.data ?? [];
          return ListView.builder(
            itemCount: report.length,
            itemBuilder: (context, index) {
              final item = report[index];
              return ListTile(
                title: Text(item['name']),
                trailing: Text('${item['durationMinutes']} minutes'),
              );
            },
          );
        },
      ),
    );
  }
}
