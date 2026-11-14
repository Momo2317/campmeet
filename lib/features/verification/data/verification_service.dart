import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Verification request status
enum VerificationStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  final String value;
  const VerificationStatus(this.value);

  factory VerificationStatus.fromString(String value) {
    return VerificationStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => VerificationStatus.pending,
    );
  }
}

/// Student ID verification model
class VerificationRequest {
  final String id;
  final String userId;
  final String imageUrl;
  final VerificationStatus status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final String? reviewedBy;

  VerificationRequest({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
    this.reviewedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'imageUrl': imageUrl,
      'status': status.value,
      'submittedAt': submittedAt,
      'reviewedAt': reviewedAt,
      'rejectionReason': rejectionReason,
      'reviewedBy': reviewedBy,
    };
  }

  factory VerificationRequest.fromMap(String id, Map<String, dynamic> map) {
    return VerificationRequest(
      id: id,
      userId: map['userId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      status: VerificationStatus.fromString(map['status'] ?? 'pending'),
      submittedAt: map['submittedAt'] != null
          ? (map['submittedAt'] as Timestamp).toDate()
          : DateTime.now(),
      reviewedAt: map['reviewedAt'] != null
          ? (map['reviewedAt'] as Timestamp).toDate()
          : null,
      rejectionReason: map['rejectionReason'],
      reviewedBy: map['reviewedBy'],
    );
  }
}

/// Service for managing student ID verification uploads
class VerificationService {
  static final _instance = VerificationService._();

  factory VerificationService() => _instance;

  VerificationService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const int maxFileSize = 5242880; // 5MB
  // Das Plugin skaliert über minWidth/minHeight: die kürzere Kante landet bei
  // ca. 1080px, das Bild wird nie vergrößert. Das ist kein Maximum je Achse.
  static const int targetShortSide = 1080;
  static const int imageQuality = 85;

  /// Upload student ID image
  /// Returns the verification request ID
  Future<String> uploadStudentId({
    required String userId,
    required String imagePath,
  }) async {
    try {
      // Check file size
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Bild nicht gefunden');
      }

      // Compress image
      final compressedPath = await _compressImage(imagePath);
      final compressedFile = File(compressedPath);
      final fileSize = await compressedFile.length();

      if (fileSize > maxFileSize) {
        throw Exception('Datei ist zu groß. Max 5MB erlaubt.');
      }

      // Create verification request document first
      final requestRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('verificationRequests')
          .doc();

      // Upload to Firebase Storage
      final storageRef =
          _storage.ref().child('verifications/$userId/${requestRef.id}.jpg');
      await storageRef.putFile(compressedFile);
      final imageUrl = await storageRef.getDownloadURL();

      // Create verification request in Firestore
      await requestRef.set({
        'userId': userId,
        'imageUrl': imageUrl,
        'status': VerificationStatus.pending.value,
        'submittedAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'rejectionReason': null,
        'reviewedBy': null,
      });

      return requestRef.id;
    } catch (e) {
      throw Exception('Upload fehlgeschlagen: $e');
    }
  }

  /// Get verification request for a user
  Future<VerificationRequest?> getVerificationRequest(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('verificationRequests')
          .orderBy('submittedAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final doc = querySnapshot.docs.first;
      return VerificationRequest.fromMap(doc.id, doc.data());
    } catch (e) {
      throw Exception(
          'Verifizierungsanfrage konnte nicht abgerufen werden: $e');
    }
  }

  /// Get all pending verification requests (for admin)
  Future<List<VerificationRequest>> getPendingRequests() async {
    try {
      final querySnapshot = await _firestore
          .collectionGroup('verificationRequests')
          .where('status', isEqualTo: VerificationStatus.pending.value)
          .orderBy('submittedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => VerificationRequest.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception(
          'Ausstehende Anfragen konnten nicht abgerufen werden: $e');
    }
  }

  /// Get verification request by ID (with user info for admin)
  Future<Map<String, dynamic>?> getVerificationRequestWithUser(
    String requestId,
  ) async {
    try {
      // Query to find the request
      final querySnapshot = await _firestore
          .collectionGroup('verificationRequests')
          .where(FieldPath.documentId, isEqualTo: requestId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final requestDoc = querySnapshot.docs.first;
      final request =
          VerificationRequest.fromMap(requestDoc.id, requestDoc.data());

      // Get user info
      final userDoc =
          await _firestore.collection('users').doc(request.userId).get();
      final userData = userDoc.data();

      return {
        'request': request,
        'user': {
          'id': request.userId,
          'name': userData?['name'] ?? 'Unknown',
          'email': userData?['email'] ?? 'Unknown',
          'university': userData?['university'] ?? 'Unknown',
          'avatarUrl': userData?['avatarUrl'],
        },
      };
    } catch (e) {
      throw Exception('Anfrage mit Benutzer konnte nicht abgerufen werden: $e');
    }
  }

  /// Approve verification request (admin only)
  Future<void> approveVerification({
    required String userId,
    required String requestId,
    required String approvedBy,
  }) async {
    try {
      // Update verification request status
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('verificationRequests')
          .doc(requestId)
          .update({
        'status': VerificationStatus.approved.value,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': approvedBy,
      });

      // Update user as verified
      await _firestore.collection('users').doc(userId).update({
        'isVerified': true,
        'verificationMethod': 'student_id',
        'verificationDate': FieldValue.serverTimestamp(),
      });

      // Log audit
      await _firestore.collection('verificationAuditLog').add({
        'userId': userId,
        'action': 'verified',
        'method': 'student_id',
        'details': 'Student ID verification approved',
        'approvedBy': approvedBy,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Genehmigung fehlgeschlagen: $e');
    }
  }

  /// Reject verification request (admin only)
  Future<void> rejectVerification({
    required String userId,
    required String requestId,
    required String reason,
    required String rejectedBy,
  }) async {
    try {
      // Update verification request status
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('verificationRequests')
          .doc(requestId)
          .update({
        'status': VerificationStatus.rejected.value,
        'reviewedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
        'reviewedBy': rejectedBy,
      });

      // Clear verification request reference
      await _firestore.collection('users').doc(userId).update({
        'verificationRequestId': null,
      });

      // Log audit
      await _firestore.collection('verificationAuditLog').add({
        'userId': userId,
        'action': 'rejected',
        'method': 'student_id',
        'details': 'Student ID verification rejected: $reason',
        'approvedBy': rejectedBy,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ablehnung fehlgeschlagen: $e');
    }
  }

  /// Compress image to reduce file size
  Future<String> _compressImage(String imagePath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/verification_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        targetPath,
        minWidth: targetShortSide,
        minHeight: targetShortSide,
        quality: imageQuality,
        format: CompressFormat.jpeg,
      );
      return result?.path ?? imagePath;
    } catch (e) {
      debugPrint('⚠️ Fehler beim Komprimieren des Bildes: $e');
      return imagePath; // Return original if compression fails
    }
  }

  /// Delete verification image from storage
  Future<void> deleteVerificationImage(String userId, String requestId) async {
    try {
      await _storage
          .ref()
          .child('verifications/$userId/$requestId.jpg')
          .delete();
    } catch (e) {
      debugPrint('⚠️ Fehler beim Löschen der Verifizierungsimages: $e');
    }
  }
}
