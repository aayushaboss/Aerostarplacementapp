// Prototype mock data — delete when real API is wired.
// Mirrors frontend/src/mockData/mockNotifications.ts.
import '../models/notification_item.dart';

/// College/default segment.
const List<NotificationItem> mockNotifications = [
  NotificationItem(
    id: 'n1',
    group: 'Today',
    title: '3 new internships match your goals',
    body: 'Fresh Digital Marketing internships just opened — take a look.',
    type: 'opportunity',
    unread: true,
    // The exact 3 internships this notification promised (PhonePe, Zomato and
    // OYO Digital Marketing Interns from the job sheet) — not a live category
    // filter, since that would silently drift out of sync with "3". See
    // OpportunityListScreen.ids. (None of them is one of the jobs the seed
    // applications in mock_applications.dart already applied to, because
    // OpportunityListScreen hides already-applied roles.)
    route: '/opportunities?title=New%20internships%20for%20you'
        '&ids=JOB0041,JOB0051,JOB0061',
  ),
  NotificationItem(
    id: 'n2',
    group: 'Today',
    title: "You're shortlisted! 🎉",
    body: 'Razorpay wants to interview you for Digital Marketing Intern.',
    type: 'application',
    unread: true,
    route: '/application/app-seed-interview',
  ),
  NotificationItem(
    id: 'n3',
    group: 'Earlier',
    title: 'Welcome to Aerostar Edge',
    body: 'Your journey to the right next step starts here.',
    type: 'system',
    unread: false,
  ),
];

/// School segment — same shape/grouping as [mockNotifications], but n1/n2
/// there are internship/job-application copy that doesn't fit a segment
/// with no Applications tab and no job listings. Swapped for the school
/// equivalents of the same two moments: new course recommendations, and a
/// booked-session confirmation.
const List<NotificationItem> mockSchoolNotifications = [
  NotificationItem(
    id: 'sn1',
    group: 'Today',
    title: '3 new courses match your interests',
    body: 'Fresh picks based on your aptitude results.',
    type: 'course',
    unread: true,
    route: '/tabs/browse',
  ),
  NotificationItem(
    id: 'sn2',
    group: 'Today',
    title: 'Your counseling session is confirmed',
    body: 'Ms. Ananya Rao will see you Thu, 14 Aug at 02:30 PM.',
    type: 'application',
    unread: true,
    route: '/tabs/sessions',
  ),
  NotificationItem(
    id: 'n3',
    group: 'Earlier',
    title: 'Welcome to Aerostar Edge',
    body: 'Your journey to the right next step starts here.',
    type: 'system',
    unread: false,
  ),
];
