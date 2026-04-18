import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  // ─── Generic upload ──────────────────────────────────────────────────────

  Future<String?> _upload(String path, File file) async {
    try {
      final ref = _storage.ref().child(path);
      final task = await ref.putFile(file);
      return await task.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // ─── Worker documents ────────────────────────────────────────────────────

  /// Worker face photo
  Future<String?> uploadWorkerPhoto(String workerId, File file) =>
      _upload('workers/$workerId/photo.jpg', file);

  /// CNIC front side
  Future<String?> uploadCnicFront(String workerId, File file) =>
      _upload('workers/$workerId/cnic_front.jpg', file);

  /// CNIC back side
  Future<String?> uploadCnicBack(String workerId, File file) =>
      _upload('workers/$workerId/cnic_back.jpg', file);

  /// Police verification document
  Future<String?> uploadPoliceVerifDoc(String workerId, File file) =>
      _upload('workers/$workerId/police_verif.jpg', file);

  // ─── Vehicle documents ───────────────────────────────────────────────────

  /// Vehicle registration card photo
  Future<String?> uploadVehicleRegCard(String vehicleId, File file) =>
      _upload('vehicles/$vehicleId/reg_card.jpg', file);

  // ─── Pet documents ───────────────────────────────────────────────────────

  /// Pet photo
  Future<String?> uploadPetPhoto(String petId, File file) =>
      _upload('pets/$petId/photo.jpg', file);

  /// Pet vaccination document
  Future<String?> uploadPetVaccinationDoc(String petId, File file) =>
      _upload('pets/$petId/vaccination.jpg', file);

  // ─── Resident documents ──────────────────────────────────────────────────

  /// Resident CNIC photo
  Future<String?> uploadResidentCnic(String residentId, File file) =>
      _upload('residents/$residentId/cnic.jpg', file);

  /// Resident driving license photo
  Future<String?> uploadDrivingLicense(String residentId, File file) =>
      _upload('residents/$residentId/driving_license.jpg', file);

  /// Resident clinic/medical photo
  Future<String?> uploadClinicPhoto(String residentId, File file) =>
      _upload('residents/$residentId/clinic_photo.jpg', file);

  // ─── Delete ──────────────────────────────────────────────────────────────

  Future<void> deleteFile(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {}
  }
}
