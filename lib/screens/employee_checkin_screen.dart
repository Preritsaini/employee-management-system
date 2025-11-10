import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/face_detection_service.dart';
import '../models/attendance.dart';
import '../models/employee.dart';

class EmployeeCheckInScreen extends StatefulWidget {
  const EmployeeCheckInScreen({super.key});

  @override
  State<EmployeeCheckInScreen> createState() => _EmployeeCheckInScreenState();
}

class _EmployeeCheckInScreenState extends State<EmployeeCheckInScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  XFile? _capturedImage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
        );
        await _cameraController!.initialize();
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera initialization failed: $e')),
        );
      }
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      XFile image = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = image;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture image: $e')),
        );
      }
    }
  }

  Future<void> _processCheckIn() async {
    if (_capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture an image first')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final employee = await authService.getCurrentEmployee();

      if (employee == null) {
        throw Exception('Employee not found');
      }

      final faceDetectionService = FaceDetectionService();
      Employee? employeeMatch;
      try {
        employeeMatch = await faceDetectionService.recognizeFace(
          File(_capturedImage!.path),
        );
      } finally {
        faceDetectionService.dispose();
      }

      if (employeeMatch == null || employeeMatch.id != employee.id) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Face recognition failed. Please try again.')),
          );
        }
        return;
      }

      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final storageService = Provider.of<StorageService>(context, listen: false);

      Attendance? todayAttendance =
          await firestoreService.getTodayAttendance(employee.id);

      if (todayAttendance != null) {
        String photoUrl = await storageService.uploadAttendancePhoto(
          File(_capturedImage!.path),
          employee.id,
          'checkout',
        );

        todayAttendance = Attendance(
          id: todayAttendance.id,
          employeeId: todayAttendance.employeeId,
          employeeName: todayAttendance.employeeName,
          checkInTime: todayAttendance.checkInTime,
          checkOutTime: DateTime.now(),
          checkInPhotoUrl: todayAttendance.checkInPhotoUrl,
          checkOutPhotoUrl: photoUrl,
          status: 'checked_out',
        );

        await firestoreService.updateAttendance(todayAttendance);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Check-out successful!')),
          );
        }
      } else {
        String photoUrl = await storageService.uploadAttendancePhoto(
          File(_capturedImage!.path),
          employee.id,
          'checkin',
        );

        Attendance attendance = Attendance(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          employeeId: employee.id,
          employeeName: employee.name,
          checkInTime: DateTime.now(),
          checkInPhotoUrl: photoUrl,
          status: 'checked_in',
        );

        await firestoreService.addAttendance(attendance);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Check-in successful!')),
          );
        }
      }

      setState(() {
        _capturedImage = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check In/Out'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: _isInitialized
          ? Column(
              children: [
                Expanded(
                  child: _capturedImage != null
                      ? Image.file(File(_capturedImage!.path))
                      : CameraPreview(_cameraController!),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (_capturedImage != null) ...[
                        ElevatedButton(
                          onPressed: _isProcessing
                              ? null
                              : () {
                                  setState(() {
                                    _capturedImage = null;
                                  });
                                },
                          child: const Text('Retake'),
                        ),
                        ElevatedButton(
                          onPressed: _isProcessing ? null : _processCheckIn,
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Submit'),
                        ),
                      ] else
                        FloatingActionButton(
                          onPressed: _captureImage,
                          child: const Icon(Icons.camera_alt),
                        ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
