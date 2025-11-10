import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/employee.dart';
import '../models/attendance.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Employee>> getEmployees() {
    return _firestore
        .collection('employees')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Employee.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<List<Employee>> getEmployeesList() async {
    QuerySnapshot snapshot = await _firestore.collection('employees').get();
    return snapshot.docs
        .map((doc) => Employee.fromMap(
            doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<Employee?> getEmployee(String employeeId) async {
    DocumentSnapshot doc =
        await _firestore.collection('employees').doc(employeeId).get();
    if (doc.exists) {
      return Employee.fromMap(
          doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<void> updateEmployee(Employee employee) async {
    try {
      await _firestore
          .collection('employees')
          .doc(employee.id)
          .set(employee.toMap(), SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw Exception('Firestore error (${e.code}): ${e.message ?? "Failed to update employee"}');
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains('Exception: ')) {
        errorMsg = errorMsg.split('Exception: ').last;
      }
      throw Exception('Failed to update employee: $errorMsg');
    }
  }

  Future<void> createEmployee(Employee employee) async {
    try {
      await _firestore
          .collection('employees')
          .doc(employee.id)
          .set(employee.toMap());
    } catch (e) {
      throw Exception('Failed to create employee: $e');
    }
  }

  Future<void> deleteEmployee(String employeeId) async {
    await _firestore.collection('employees').doc(employeeId).delete();
  }

  Future<void> addAttendance(Attendance attendance) async {
    try {
      await _firestore
          .collection('attendance')
          .doc(attendance.id)
          .set(attendance.toMap());
    } catch (e) {
      throw Exception('Failed to add attendance: $e');
    }
  }

  Future<void> updateAttendance(Attendance attendance) async {
    try {
      await _firestore
          .collection('attendance')
          .doc(attendance.id)
          .set(attendance.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update attendance: $e');
    }
  }

  Stream<List<Attendance>> getAttendanceRecords(String? employeeId) {
    Query query = _firestore.collection('attendance').orderBy('checkInTime', descending: true);
    if (employeeId != null) {
      query = query.where('employeeId', isEqualTo: employeeId);
    }
    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Attendance.fromMap(
            doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  Future<Attendance?> getTodayAttendance(String employeeId) async {
    DateTime today = DateTime.now();
    DateTime startOfDay = DateTime(today.year, today.month, today.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    QuerySnapshot snapshot = await _firestore
        .collection('attendance')
        .where('employeeId', isEqualTo: employeeId)
        .where('checkInTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('checkInTime', isLessThan: Timestamp.fromDate(endOfDay))
        .where('status', isEqualTo: 'checked_in')
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return Attendance.fromMap(
          snapshot.docs.first.data() as Map<String, dynamic>,
          snapshot.docs.first.id);
    }
    return null;
  }

  Future<bool> hasAnyAdmin() async {
    QuerySnapshot snapshot = await _firestore
        .collection('employees')
        .where('isAdmin', isEqualTo: true)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}
