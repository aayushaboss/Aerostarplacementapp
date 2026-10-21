/// Groups a filtered result list by category — used wherever a multi-
/// category filter (e.g. Courses' category facet) can otherwise interleave
/// several categories' cards together, making it hard to browse "all the
/// Technology cards" (or any one category) in one continuous run.
///
/// Preserves each item's original relative order within its own group. If
/// [order] is given (e.g. the exact order categories were selected in a
/// filter screen), groups are emitted in that order; any category present
/// in the results but not in [order] is appended after, in first-seen
/// order. Without [order], every group is emitted in first-seen order.
/// Categories with zero matching items are omitted entirely — never an
/// empty group with just a heading and nothing under it.
Map<String, List<T>> groupByCategory<T>(List<T> items, String Function(T item) categoryOf, {List<String>? order}) {
  final grouped = <String, List<T>>{};
  for (final item in items) {
    grouped.putIfAbsent(categoryOf(item), () => []).add(item);
  }
  if (order == null) return grouped;

  final ordered = <String, List<T>>{};
  for (final category in order) {
    final items = grouped.remove(category);
    if (items != null) ordered[category] = items;
  }
  // Anything left in `grouped` wasn't in `order` — append it after, in the
  // same first-seen order it already has.
  ordered.addAll(grouped);
  return ordered;
}
