/// Reprogrammation des rappels, appelée après chaque changement (section 10.2).
abstract interface class ReminderScheduler {
  Future<void> rescheduleAll();
}

/// Sans effet tant que les notifications (phase 2) ne sont pas branchées.
class NoopReminderScheduler implements ReminderScheduler {
  const NoopReminderScheduler();

  @override
  Future<void> rescheduleAll() async {}
}
