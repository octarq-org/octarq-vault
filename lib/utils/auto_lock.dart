/// Shared rule for auto-lock after returning from background.
bool shouldLockAfterBackground({
  required DateTime pausedAt,
  required DateTime now,
  required int limitMinutes,
}) {
  return now.difference(pausedAt).inMinutes >= limitMinutes;
}
