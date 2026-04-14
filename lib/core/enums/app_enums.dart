enum UserRole {
  superAdmin,
  securityManager,
  securitySupervisor,
  gateClerk,
  employer,
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
}

enum SyncStatus {
  synced,
  pendingSync,
}

enum ReportType {
  dailyGateLog,
  presenceSnapshot,
  activeWorkerList,
  employerStaffList,
  multipleFlagsHistory,
  expiryAlerts,
  overrideLog,
}
