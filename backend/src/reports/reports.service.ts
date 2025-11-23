import { Injectable } from '@nestjs/common';
import { AttendanceService } from '../attendance/attendance.service';
import { Workbook } from 'exceljs';

@Injectable()
export class ReportsService {
  constructor(private readonly attendanceService: AttendanceService) {}

  async getAttendanceReportForClass(classId: string): Promise<any> {
    const records = await this.attendanceService.getAttendanceForClass(classId);
    const studentDurations: { [key: string]: { name: string, duration: number, lastJoin: Date | null } } = {};

    for (const record of records) {
      const studentId = record.user.user_id;
      if (!studentDurations[studentId]) {
        studentDurations[studentId] = { name: record.user.full_name, duration: 0, lastJoin: null };
      }

      if (record.status === 'joined') {
        studentDurations[studentId].lastJoin = record.timestamp;
      } else if (record.status === 'left' && studentDurations[studentId].lastJoin) {
        const duration = record.timestamp.getTime() - studentDurations[studentId].lastJoin!.getTime();
        studentDurations[studentId].duration += duration;
        studentDurations[studentId].lastJoin = null;
      }
    }

    return Object.values(studentDurations).map(s => ({
      name: s.name,
      durationMinutes: Math.round(s.duration / 60000),
    }));
  }

  async generateAttendanceReportExcel(classId: string): Promise<Buffer> {
    const reportData = await this.getAttendanceReportForClass(classId);

    const workbook = new Workbook();
    const worksheet = workbook.addWorksheet('Attendance Report');

    worksheet.columns = [
      { header: 'Student Name', key: 'name', width: 30 },
      { header: 'Duration (Minutes)', key: 'durationMinutes', width: 20 },
    ];

    worksheet.addRows(reportData);

    const buffer = await workbook.xlsx.writeBuffer();
    return buffer as unknown as Buffer;
  }
}
