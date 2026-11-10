/// Unique source de « maintenant » de l'application (section 5.1).
abstract interface class Clock {
  DateTime nowUtc();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

/// Délai jusqu'au début de la prochaine minute.
Duration untilNextMinute(DateTime now) => Duration(
  milliseconds:
      Duration.millisecondsPerMinute -
      (now.second * Duration.millisecondsPerSecond + now.millisecond),
);
