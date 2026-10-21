/// Shared "3d ago" / "Just now" formatter — used anywhere a timestamp needs
/// to read as relative recency instead of a raw date (application timelines,
/// applications list).
String relativeTimeLabel(DateTime at) {
  final diff = DateTime.now().difference(at);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${at.day}/${at.month}/${at.year}';
}
