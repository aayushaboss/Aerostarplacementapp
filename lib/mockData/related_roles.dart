// Prototype mock data — delete when real API is wired.
/// Adjacent-field recommendations — picking a role surfaces a few related
/// ones alongside it. Shared by onboarding's role picker (goals_screen.dart)
/// and the college Home feed's "related field" carousel backfill
/// (college_feed_screen.dart).
const Map<String, List<String>> relatedRoles = {
  'Marketing': ['Social Media Marketing', 'Sales & Business Development', 'Graphic Designing'],
  'Sales & Business Development': ['Marketing', 'Operations', 'Social Media Marketing'],
  'Social Media Marketing': ['Marketing', 'Graphic Designing', 'Sales & Business Development'],
  'Human Resource': ['Operations', 'Finance & Accounting', 'Sales & Business Development'],
  'Operations': ['Sales & Business Development', 'Finance & Accounting', 'Human Resource'],
  'Graphic Designing': ['Social Media Marketing', 'Marketing', 'Operations'],
  'Finance & Accounting': ['Operations', 'Human Resource', 'Sales & Business Development'],
};
