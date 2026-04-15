import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/enums/app_enums.dart';

class RegistrationFormState {
  // Step 1 - Personal Info
  final String name;
  final String cnic;
  final DateTime? cnicExpiry;
  final DateTime? dob;
  final WorkerType workerType;
  final NatureOfService natureOfService;
  final String photoUrl;

  // Step 2 - Employment Info
  final String employerId;
  final String houseNumber;
  final String arrivalWindow;

  // Step 3 - Police Verification
  final bool policeVerified;
  final DateTime? policeVerifDate;
  final String policeVerifRefNumber;
  final DateTime? policeVerifExpiry;

  // UI state
  final int currentStep;
  final bool isSubmitting;
  final String? errorMessage;
  final bool cnicDuplicate;

  const RegistrationFormState({
    this.name = '',
    this.cnic = '',
    this.cnicExpiry,
    this.dob,
    this.workerType = WorkerType.houseMaid,
    this.natureOfService = NatureOfService.fullTime,
    this.photoUrl = '',
    this.employerId = '',
    this.houseNumber = '',
    this.arrivalWindow = '',
    this.policeVerified = false,
    this.policeVerifDate,
    this.policeVerifRefNumber = '',
    this.policeVerifExpiry,
    this.currentStep = 0,
    this.isSubmitting = false,
    this.errorMessage,
    this.cnicDuplicate = false,
  });

  RegistrationFormState copyWith({
    String? name,
    String? cnic,
    DateTime? cnicExpiry,
    DateTime? dob,
    WorkerType? workerType,
    NatureOfService? natureOfService,
    String? photoUrl,
    String? employerId,
    String? houseNumber,
    String? arrivalWindow,
    bool? policeVerified,
    DateTime? policeVerifDate,
    String? policeVerifRefNumber,
    DateTime? policeVerifExpiry,
    int? currentStep,
    bool? isSubmitting,
    String? errorMessage,
    bool? cnicDuplicate,
  }) {
    return RegistrationFormState(
      name: name ?? this.name,
      cnic: cnic ?? this.cnic,
      cnicExpiry: cnicExpiry ?? this.cnicExpiry,
      dob: dob ?? this.dob,
      workerType: workerType ?? this.workerType,
      natureOfService: natureOfService ?? this.natureOfService,
      photoUrl: photoUrl ?? this.photoUrl,
      employerId: employerId ?? this.employerId,
      houseNumber: houseNumber ?? this.houseNumber,
      arrivalWindow: arrivalWindow ?? this.arrivalWindow,
      policeVerified: policeVerified ?? this.policeVerified,
      policeVerifDate: policeVerifDate ?? this.policeVerifDate,
      policeVerifRefNumber: policeVerifRefNumber ?? this.policeVerifRefNumber,
      policeVerifExpiry: policeVerifExpiry ?? this.policeVerifExpiry,
      currentStep: currentStep ?? this.currentStep,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      cnicDuplicate: cnicDuplicate ?? this.cnicDuplicate,
    );
  }
}

class RegistrationFormNotifier extends StateNotifier<RegistrationFormState> {
  RegistrationFormNotifier() : super(RegistrationFormState());

  void updateStep1({
    String? name,
    String? cnic,
    DateTime? cnicExpiry,
    DateTime? dob,
    WorkerType? workerType,
    NatureOfService? natureOfService,
    String? photoUrl,
  }) {
    state = state.copyWith(
      name: name,
      cnic: cnic,
      cnicExpiry: cnicExpiry,
      dob: dob,
      workerType: workerType,
      natureOfService: natureOfService,
      photoUrl: photoUrl,
    );
  }

  void updateStep2({
    String? employerId,
    String? houseNumber,
    String? arrivalWindow,
  }) {
    state = state.copyWith(
      employerId: employerId,
      houseNumber: houseNumber,
      arrivalWindow: arrivalWindow,
    );
  }

  void updateStep3({
    bool? policeVerified,
    DateTime? policeVerifDate,
    String? policeVerifRefNumber,
    DateTime? policeVerifExpiry,
  }) {
    state = state.copyWith(
      policeVerified: policeVerified,
      policeVerifDate: policeVerifDate,
      policeVerifRefNumber: policeVerifRefNumber,
      policeVerifExpiry: policeVerifExpiry,
    );
  }

  void goToStep(int step) => state = state.copyWith(currentStep: step);
  void nextStep() => state = state.copyWith(currentStep: state.currentStep + 1);
  void prevStep() => state = state.copyWith(currentStep: state.currentStep - 1);
  void setCnicDuplicate(bool value) => state = state.copyWith(cnicDuplicate: value);
  void setSubmitting(bool value) => state = state.copyWith(isSubmitting: value);
  void setError(String? message) => state = state.copyWith(errorMessage: message);
  void reset() => state = RegistrationFormState();
}

final registrationFormProvider =
    StateNotifierProvider.autoDispose<RegistrationFormNotifier, RegistrationFormState>(
  (ref) => RegistrationFormNotifier(),
);
