import 'package:cloud_firestore/cloud_firestore.dart';

class Employee {
  final String id;
  final String employeeId;
  final String name;
  final String email;
  final String role;
  final String? photoUrl;
  final DateTime createdAt;
  final bool isAdmin;
  final Map<String, dynamic>? faceEncoding;

  Employee({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl,
    required this.createdAt,
    this.isAdmin = false,
    this.faceEncoding,
  });

  factory Employee.fromMap(Map<String, dynamic> map, String id) {
    return Employee(
      id: id,
      employeeId: map['employeeId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      photoUrl: map['photoUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAdmin: map['isAdmin'] ?? false,
      faceEncoding: map['faceEncoding'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'name': name,
      'email': email,
      'role': role,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAdmin': isAdmin,
      'faceEncoding': faceEncoding,
    };
  }
}
