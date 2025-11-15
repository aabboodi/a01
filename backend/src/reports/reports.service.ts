import { Injectable } from '@nestjs/common';
import { AttendanceService } from '../attendance/attendance.service';
import { AttendanceRecord, AttendanceStatus } from '../attendance/entities/attendance-record.entity';

@Injectable()
export class ReportsService {
  constructor(private readonly attendanceService: AttendanceService) {}

  async getAttendanceReportForClass(classId: string): Promise<any> {
    const records = await this.attendanceService.getAttendanceForClass(classId);

    // This is a simplified report generation logic. A more robust solution
    // would handle multiple sessions and calculate duration more accurately.
    const studentDurations: { [key: string]: { name: string, duration: number, lastJoin: Date | null } } = {};

    for (const record of records) {
      const studentId = record.user.user_id;
      if (!studentDurations[studentId]) {
        studentDurations[studentId] = { name: record.user.full_name, duration: 0, lastJoin: null };
      }

      if (record.status === AttendanceStatus.JOINED) {
        studentDurations[studentId].lastJoin = record.timestamp;
      } else if (record.status === AttendanceStatus.LEFT && studentDurations[studentId].lastJoin) {
        const duration = record.timestamp.getTime() - studentDurations[studentId].lastJoin!.getTime();
        studentDurations[studentId].duration += duration;
        studentDurations[studentId].lastJoin = null;
      }
    }

    // Convert durations from ms to minutes
    const report = Object.values(studentDurations).map(s => ({
      name: s.name,
      durationMinutes: Math.round(s.duration / 60000),
    }));

    return report;
  }
}
