enum UserRole {
  superAdmin,
  securityManager,
  securitySupervisor,
  gateClerk,
  resident,   // replaces employer
  worker,
}

enum WorkerStatus {
  pendingApproval,
  active,
  suspended,
  blacklisted,
  inactive,
}

enum WorkerType {
  houseMaid,
  qari,
  tutor,
  carWasher,
  servant,
  cook,
  driver,
  other,
}

enum NatureOfService {
  dayCare,
  fullTime,
}

enum GateEventType {
  entry,
  exit,
  autoExit,
}

enum GateEventMethod {
  qrScan,
  manualClerk,
}

enum PresenceStatus {
  inside,
  outside,
}

enum RegistrationRequestType {
  newWorker,
  subEmployerLink,
}

enum RegistrationRequestStatus {
  pending,
  underReview,
  approved,
  rejected,
  needsMoreInfo,
}

enum TerminationOutcome {
  cleanTermination,
  blacklisted,
}

enum TerminationReasonCategory {
  endOfContract,
  misconduct,
  theft,
  behaviouralIssue,
  noLongerRequired,
  other,
}

enum ManagerDecision {
  blacklistApproved,
  flagRejected,
  pendingReview,
}

enum AssignmentStatus {
  active,
  suspended,
  terminated,
}

enum SubEmployerStatus {
  active,
  removed,
}

enum NotificationType {
  entry,
  exit,
  autoExit,
  suspensionAlert,
  blacklistAlert,
  verifExpiry,
  contractExpiry,
  guestArrival,
  guestExit,
  petApproval,
  announcement,
  cardExpiry,
}

enum SyncStatus {
  synced,
  pendingSync,
}

enum ReportType {
  dailyGateLog,
  presenceSnapshot,
  activeWorkerList,
  residentStaffList,
  multipleFlagsHistory,
  expiryAlerts,
  overrideLog,
  guestVisitLog,
  vehicleLog,
  emergencyMuster,
  accessFrequency,
  petRegistry,
}

// ── V2 new enums ──────────────────────────────────────────────────────────────

enum VehicleType {
  car,
  motorcycle,
  van,
  truck,
  other,
}

enum VehicleEventMethod {
  rfid,       // future — when hardware live
  manual,     // current operational mode
  qr,
}

enum GuestVisitStatus {
  inside,
  exited,
  expired,
}

enum PetStatus {
  pending,
  approved,
  rejected,
}

enum PetType {
  dog,
  cat,
  bird,
  other,
}

enum FamilyRelation {
  son,
  daughter,
  wife,
  husband,
  father,
  mother,
  brother,
  sister,
  other,
}

enum InitiatedByRole {
  resident,
  gateClerk,
  securitySupervisor,
  securityManager,
}

enum ResidentStatus {
  pending,
  approved,
  suspended,
}
