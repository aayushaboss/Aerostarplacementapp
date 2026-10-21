// Prototype mock data — delete when real API is wired.
// Mirrors frontend/src/mockData/mockResume.ts.
import '../models/parsed_resume.dart';

const mockParsedResume = ParsedResume(
  name: 'Aarav Sharma',
  education: [
    ResumeEducation(
      degree: 'B.Tech Computer Science',
      institution: 'VIT Vellore',
      duration: '2022 - 2026',
    ),
  ],
  skills: ['React', 'TypeScript', 'Python', 'SQL', 'Figma'],
  projects: [
    ResumeProject(
      title: 'Campus Placement Portal',
      description: 'Built a React Native app for browsing internships and tracking applications.',
    ),
  ],
  links: ['https://github.com/demo', 'https://linkedin.com/in/demo'],
);
