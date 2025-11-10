import 'dart:io';
import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/employee.dart';
import 'firestore_service.dart';

class FaceDetectionService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      enableClassification: true,
      enableTracking: false,
      minFaceSize: 0.1,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );
  final FirestoreService _firestoreService = FirestoreService();

  Future<bool> detectFace(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final List<Face> faces = await _faceDetector.processImage(inputImage);
      return faces.isNotEmpty;
    } catch (e) {
      throw Exception('Face detection failed: $e');
    }
  }

  Future<Map<String, dynamic>?> extractFaceEncoding(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final List<Face> faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        return null;
      }

      Face face = faces.first;

      Map<String, dynamic> encoding = {
        'landmarks': _extractLandmarks(face),
        'contours': _extractContours(face),
        'bounds': {
          'left': face.boundingBox.left,
          'top': face.boundingBox.top,
          'width': face.boundingBox.width,
          'height': face.boundingBox.height,
        },
        'headEulerAngleY': face.headEulerAngleY,
        'headEulerAngleZ': face.headEulerAngleZ,
        'smilingProbability': face.smilingProbability,
        'leftEyeOpenProbability': face.leftEyeOpenProbability,
        'rightEyeOpenProbability': face.rightEyeOpenProbability,
      };

      return encoding;
    } catch (e) {
      throw Exception('Face encoding extraction failed: $e');
    }
  }

  Map<String, dynamic> _extractLandmarks(Face face) {
    Map<String, dynamic> landmarks = {};
    face.landmarks.forEach((type, landmark) {
      if (landmark != null) {
        landmarks[type.toString()] = {
          'x': landmark.position.x.toDouble(),
          'y': landmark.position.y.toDouble(),
        };
      }
    });
    return landmarks;
  }

  Map<String, dynamic> _extractContours(Face face) {
    Map<String, dynamic> contours = {};
    face.contours.forEach((type, contour) {
      if (contour != null) {
        List<Map<String, double>> points = [];
        for (var point in contour.points) {
          points.add({'x': point.x.toDouble(), 'y': point.y.toDouble()});
        }
        contours[type.toString()] = points;
      }
    });
    return contours;
  }

  double _calculateSimilarity(
      Map<String, dynamic> encoding1, Map<String, dynamic> encoding2) {
    try {
      double similarity = 0.0;
      int count = 0;

      if (encoding1['landmarks'] != null && encoding2['landmarks'] != null) {
        Map<String, dynamic> landmarks1 = encoding1['landmarks'];
        Map<String, dynamic> landmarks2 = encoding2['landmarks'];

        for (String key in landmarks1.keys) {
          if (landmarks2.containsKey(key)) {
            Map<String, dynamic> point1 = landmarks1[key];
            Map<String, dynamic> point2 = landmarks2[key];

            double distance = _euclideanDistance(
              point1['x']?.toDouble() ?? 0.0,
              point1['y']?.toDouble() ?? 0.0,
              point2['x']?.toDouble() ?? 0.0,
              point2['y']?.toDouble() ?? 0.0,
            );

            similarity += 1.0 / (1.0 + distance);
            count++;
          }
        }
      }

      return count > 0 ? similarity / count : 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  double _euclideanDistance(double x1, double y1, double x2, double y2) {
    return sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
  }

  Future<Employee?> recognizeFace(File imageFile) async {
    try {
      Map<String, dynamic>? faceEncoding = await extractFaceEncoding(imageFile);
      if (faceEncoding == null) {
        return null;
      }

      List<Employee> employees = await _firestoreService.getEmployeesList();
      Employee? bestMatch;
      double bestSimilarity = 0.6;

      for (Employee employee in employees) {
        if (employee.faceEncoding != null) {
          double similarity = _calculateSimilarity(
              faceEncoding, employee.faceEncoding as Map<String, dynamic>);
          if (similarity > bestSimilarity) {
            bestSimilarity = similarity;
            bestMatch = employee;
          }
        }
      }

      return bestMatch;
    } catch (e) {
      throw Exception('Face recognition failed: $e');
    }
  }

  void dispose() {
    _faceDetector.close();
  }
}
