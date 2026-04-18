import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/enums/app_enums.dart';

class RegistrationFormState {
  // Step 1 — Personal info
  final String name;
  final String cnic;
  final DateTime? cnicExpiry;
  final DateTime? dob;
  final WorkerType workerType;
  final NatureOfService natureOfService;
  final String photoUrl;
  final String cnicPhotoUrlFront;
  final String cnicPhotoUrlBack;

  // Step 2 — Employment info
  final String residentId;      // renamed from employerId
  final String houseNumber;
  final String arrivalWindow;
  final String shiftStart;
  final String shiftEnd;
  final bool shiftEnforcement;

  // Step 3 — Police verification
  final bool policeVerified;
  final DateTime? policeVerifDate;
  final String policeVerifRefNumber;
  final DateTime? policeVerifExpiry;
  final String policeVerifPhotoUrl;

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
    this.cnicPhotoUrlFront = '',
    this.cnicPhotoUrlBack = '',
    this.residentId = '',
    this.houseNumber = '',
    this.arrivalWindow = '',
    this.shiftStart = '',
    this.shiftEnd = '',
    this.shiftEnforcement = false,
    this.policeVerified = false,
    this.policeVerifDate,
    this.policeVerifRefNumber = '',
    this.policeVerifExpiry,
    this.policeVerifPhotoUrl = '',
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
    String? cnicPhotoUrlFront,
    String? cnicPhotoUrlBack,
    String? residentId,
    String? houseNumber,
    String? arrivalWindow,
    String? shiftStart,
    String? shiftEnd,
    bool? shiftEnforcement,
    bool? policeVerified,
    DateTime? policeVerifDate,
    String? policeVerifRefNumber,
    DateTime? policeVerifExpiry,
    String? policeVerifPhotoUrl,
    int? currentStep,
    bool? isSubmitting,
    String? errorMessage,
    bool? cnicDuplicate,
  }) {
    return RegistrationFormState(
      name:                name ?? this.name,
      cnic:                cnic ?? this.cnic,
      cnicExpiry:          cnicExpiry ?? this.cnicExpiry,
      dob:                 dob ?? this.dob,
      workerType:          workerType ?? this.workerType,
      natureOfService:     natureOfService ?? this.natureOfService,
      photoUrl:            photoUrl ?? this.photoUrl,
      cnicPhotoUrlFront:   cnicPhotoUrlFront ?? this.cnicPhotoUrlFront,
      cnicPhotoUrlBack:    cnicPhotoUrlBack ?? this.cnicPhotoUrlBack,
      residentId:          residentId ?? this.residentId,
      houseNumber:         houseNumber ?? this.houseNumber,
      arrivalWindow:       arrivalWindow ?? this.arrivalWindow,
      shiftStart:          shiftStart ?? this.shiftStart,
      shiftEnd:            shiftEnd ?? this.shiftEnd,
      shiftEnforcement:    shiftEnforcement ?? this.shiftEnforcement,
      policeVerified:      policeVerified ?? this.policeVerified,
      policeVerifDate:     policeVerifDate ?? this.policeVerifDate,
      policeVerifRefNumber: policeVerifRefNumber ?? this.policeVerifRefNumber,
      policeVerifExpiry:   policeVerifExpiry ?? this.policeVerifExpiry,
      policeVerifPhotoUrl: policeVerifPhotoUrl ?? this.policeVerifPhotoUrl,
      currentStep:         currentStep ?? this.currentStep,
      isSubmitting:        isSubmitting ?? this.isSubmitting,
      errorMessage:        errorMessage,
      cnicDuplicate:       cnicDuplicate ?? this.cnicDuplicate,
    );
  }
}

class RegistrationFormNotifier extends StateNotifier<RegistrationFormState> {
  RegistrationFormNotifier() : super(const RegistrationFormState());

  void updateStep1({
    String? name,
    String? cnic,
    DateTime? cnicExpiry,
    DateTime? dob,
    WorkerType? workerType,
    NatureOfService? natureOfService,
    String? photoUrl,
    String? cnicPhotoUrlFront,
    String? cnicPhotoUrlBack,
  }) {
    state = state.copyWith(
      name:              name,
      cnic:              cnic,
      cnicExpiry:        cnicExpiry,
      dob:               dob,
      workerType:        workerType,
      natureOfService:   natureOfService,
      photoUrl:          photoUrl,
      cnicPhotoUrlFront: cnicPhotoUrlFront,
      cnicPhotoUrlBack:  cnicPhotoUrlBack,
    );
  }

  void updateStep2({
    String? residentId,
    String? houseNumber,
    String? arrivalWindow,
    String? shiftStart,
    String? shiftEnd,
    bool? shiftEnforcement,
  }) {
    state = state.copyWith(
      residentId:       residentId,
      houseNumber:      houseNumber,
      arrivalWindow:    arrivalWindow,
      shiftStart:       shiftStart,
      shiftEnd:         shiftEnd,
      shiftEnforcement: shiftEnforcement,
    );
  }

  void updateStep3({
    bool? policeVerified,
    DateTime? policeVerifDate,
    String? policeVerifRefNumber,
    DateTime? policeVerifExpiry,
    String? policeVerifPhotoUrl,
  }) {
    state = state.copyWith(
      policeVerified:      policeVerified,
      policeVerifDate:     policeVerifDate,
      policeVerifRefNumber: policeVerifRefNumber,
      policeVerifExpiry:   policeVerifExpiry,
      policeVerifPhotoUrl: policeVerifPhotoUrl,
    );
  }

  void goToStep(int step) => state = state.copyWith(currentStep: step);
  void nextStep() => state = state.copyWith(currentStep: state.currentStep + 1);
  void prevStep() => state = state.copyWith(currentStep: state.currentStep - 1);
  void setCnicDuplicate(bool value) => state = state.copyWith(cnicDuplicate: value);
  void setSubmitting(bool value) => state = state.copyWith(isSubmitting: value);
  void setError(String? message) => state = state.copyWith(errorMessage: message);
  void reset() => state = const RegistrationFormState();
}

final registrationFormProvider =
    StateNotifierProvider.autoDispose<RegistrationFormNotifier, RegistrationFormState>(
  (ref) => RegistrationFormNotifier(),
);
