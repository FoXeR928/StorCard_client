class SyncResult {
  const SyncResult({
    required this.pushed,
    required this.pulled,
    required this.deleted,
    this.error,
  });

  final int pushed;
  final int pulled;
  final int deleted;
  final String? error;

  bool get isSuccess => error == null;
}
