import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../models/attendance.dart';

class AttendanceRecordsScreen extends StatelessWidget {
  const AttendanceRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Records'),
      ),
      body: StreamBuilder<List<Attendance>>(
        stream: Provider.of<FirestoreService>(context).getAttendanceRecords(null),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No attendance records found'));
          }

          List<Attendance> records = snapshot.data!;
          Map<String, List<Attendance>> groupedRecords = {};

          for (Attendance record in records) {
            String dateKey = DateFormat('yyyy-MM-dd').format(record.checkInTime);
            if (!groupedRecords.containsKey(dateKey)) {
              groupedRecords[dateKey] = [];
            }
            groupedRecords[dateKey]!.add(record);
          }

          List<String> sortedDates = groupedRecords.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              String dateKey = sortedDates[index];
              List<Attendance> dayRecords = groupedRecords[dateKey]!;
              DateTime date = DateFormat('yyyy-MM-dd').parse(dateKey);

              return ExpansionTile(
                title: Text(DateFormat('EEEE, MMMM d, yyyy').format(date)),
                subtitle: Text('${dayRecords.length} records'),
                children: dayRecords.map((record) {
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: record.status == 'checked_in'
                            ? Colors.green
                            : Colors.blue,
                        child: Icon(
                          record.status == 'checked_in'
                              ? Icons.login
                              : Icons.logout,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(record.employeeName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Check-in: ${DateFormat('hh:mm a').format(record.checkInTime)}'),
                          if (record.checkOutTime != null)
                            Text('Check-out: ${DateFormat('hh:mm a').format(record.checkOutTime!)}'),
                          if (record.checkOutTime != null)
                            Text(
                              'Duration: ${_formatDuration(record.workingHours)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(record.status == 'checked_in' ? 'In' : 'Out'),
                        backgroundColor: record.status == 'checked_in'
                            ? Colors.green[100]
                            : Colors.blue[100],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    return '$hours:$minutes';
  }
}


