import 'package:cloud_firestore/cloud_firestore.dart';

class Attendance {
  final String id;
  final String employeeId;
  final String employeeName;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String? checkInPhotoUrl;
  final String? checkOutPhotoUrl;
  final String status;

  Attendance({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.checkInTime,
    this.checkOutTime,
    this.checkInPhotoUrl,
    this.checkOutPhotoUrl,
    this.status = 'checked_in',
  });

  factory Attendance.fromMap(Map<String, dynamic> map, String id) {
    return Attendance(
      id: id,
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      checkInTime: (map['checkInTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      checkOutTime: (map['checkOutTime'] as Timestamp?)?.toDate(),
      checkInPhotoUrl: map['checkInPhotoUrl'],
      checkOutPhotoUrl: map['checkOutPhotoUrl'],
      status: map['status'] ?? 'checked_in',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'checkInTime': Timestamp.fromDate(checkInTime),
      'checkOutTime': checkOutTime != null ? Timestamp.fromDate(checkOutTime!) : null,
      'checkInPhotoUrl': checkInPhotoUrl,
      'checkOutPhotoUrl': checkOutPhotoUrl,
      'status': status,
    };
  }

  Duration get workingHours {
    if (checkOutTime == null) {
      return DateTime.now().difference(checkInTime);
    }
    return checkOutTime!.difference(checkInTime);
  }
}
