// Prototype mock data — delete when real API is wired.
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:flutter/widgets.dart' show IconData;

class FaqCategory {
  final String id;
  final String label;
  final IconData icon;
  const FaqCategory({required this.id, required this.label, required this.icon});
}

class FaqItem {
  final String question;
  final String answer;
  final String categoryId;
  const FaqItem({required this.question, required this.answer, required this.categoryId});
}

const mockFaqCategories = [
  FaqCategory(id: 'account', label: 'Account & Profile', icon: Ionicons.person_outline),
  FaqCategory(id: 'resume', label: 'Resume Builder', icon: Ionicons.document_text_outline),
  FaqCategory(id: 'applications', label: 'Applications & Interviews', icon: Ionicons.briefcase_outline),
  FaqCategory(id: 'bookings', label: 'Bookings & Sessions', icon: Ionicons.calendar_outline),
];

const mockFaqs = [
  // Account & Profile
  FaqItem(
    question: 'How do I edit my basic details or college info?',
    answer:
        "Go to your Profile tab and tap the Basic details card, or tap the pencil icon on your profile header — both open the same edit form.",
    categoryId: 'account',
  ),
  FaqItem(
    question: 'How do I turn on push notifications?',
    answer: "Open the Profile tab and use the notification toggle at the top of the settings list. Your browser may ask you to allow them the first time.",
    categoryId: 'account',
  ),
  FaqItem(
    question: 'Can I change my registered phone number or email?',
    answer: "Not yet in this preview build — reach out to us using the contact options below and we'll update it for you manually.",
    categoryId: 'account',
  ),
  FaqItem(
    question: 'How is my profile completion percentage calculated?',
    answer: "It's based on the checklist on your Profile tab — Basic details, Resume, Profile photo, and Video profile each contribute a share. Complete all four for 100%.",
    categoryId: 'account',
  ),
  FaqItem(
    question: 'What are Search Appearances and Recruiter Actions?',
    answer: "Search Appearances shows how often recruiters found your profile in search; Recruiter Actions shows when they've viewed or shortlisted you. Both live under your Profile tab.",
    categoryId: 'account',
  ),
  // Resume Builder
  FaqItem(
    question: 'Should I upload a PDF or build my resume in the app?',
    answer: "Either works. Profile → Resume gives you both options — if you don't have a PDF ready, \"Build it here\" walks you through a short guided quiz covering skills, education, experience, and a summary.",
    categoryId: 'resume',
  ),
  FaqItem(
    question: 'Can I edit my resume after building it?',
    answer: "Yes — open Profile → Resume and tap any section in the checklist (Education, Experience, Skills, Languages, and so on) to jump straight back into that step of the builder.",
    categoryId: 'resume',
  ),
  FaqItem(
    question: "Why can't I apply to some opportunities?",
    answer: "A few roles require a resume on file before you can apply. If you tap Apply without one, we'll take you to the resume screen first so recruiters actually have something to look at.",
    categoryId: 'resume',
  ),
  // Applications & Interviews
  FaqItem(
    question: 'What do the application statuses mean?',
    answer: "Applied → In Review → Interview → Offer, or a rejection if the role's closed. You can see the full timeline on any application's detail page.",
    categoryId: 'applications',
  ),
  FaqItem(
    question: 'I swiped to delete an application by mistake — can I get it back?',
    answer: "Tap Undo on the confirmation banner right after deleting, or open the trash icon on the Applications screen any time afterward to restore it from Recently Deleted.",
    categoryId: 'applications',
  ),
  FaqItem(
    question: 'How long do deleted applications stay recoverable?',
    answer: "They stay in Recently Deleted until you restore them or delete them forever — there's no automatic expiry in this preview build.",
    categoryId: 'applications',
  ),
  FaqItem(
    question: 'How do I prepare for an interview once I’m shortlisted?',
    answer: "Each application card has \"Mock\" (book a mock interview session) and \"Prep\" (curated courses for that specific role) shortcuts right on the card.",
    categoryId: 'applications',
  ),
  // Bookings & Sessions
  FaqItem(
    question: "What's the difference between a counseling session and a placement session?",
    answer: "Counseling sessions are career-path guidance, mainly for school students. Placement sessions cover interview prep and mock interviews for college students actively job-hunting.",
    categoryId: 'bookings',
  ),
  FaqItem(
    question: 'Can I book an offline session instead of online?',
    answer: "Yes — choose Offline when booking and you'll see the assigned office address right there, and again on your confirmation screen.",
    categoryId: 'bookings',
  ),
  FaqItem(
    question: 'How do I reschedule or cancel a booking?',
    answer: "Open Profile → Bookings and use the Reschedule or Cancel action on the session card — you'll get a fresh confirmation after any change.",
    categoryId: 'bookings',
  ),
];
