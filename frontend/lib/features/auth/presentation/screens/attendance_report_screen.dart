import 'package:flutter/material.dart';
import 'package:frontend/features/auth/application/services/reports_service.dart';

class AttendanceReportScreen extends StatefulWidget {
  final Map<String, dynamic> classData;

  const AttendanceReportScreen({Key? key, required this.classData}) : super(key: key);

  @override
  _AttendanceReportScreenState createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  final ReportsService _reportsService = ReportsService();
  Future<List<dynamic>>? _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = _reportsService.getAttendanceReport(widget.classData['class_id']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Report for ${widget.classData['class_name']}'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No attendance data available.'));
          }

          final report = snapshot.data!;
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
