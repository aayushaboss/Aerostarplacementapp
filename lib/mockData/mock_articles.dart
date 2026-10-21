// Prototype mock data — delete when real API is wired.
// Mirrors frontend/src/mockData/mockArticles.ts.
import '../models/article.dart';

const List<Article> mockArticles = [
  Article(
    id: 'art-choose-stream',
    tag: 'Career',
    title: 'How to choose the right stream after Class 10',
    image:
        'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?crop=entropy&cs=srgb&fm=jpg&q=85&w=800',
    readTime: '4 min read',
  ),
  Article(
    id: 'art-nep-explained',
    tag: 'NEP 2020',
    title: 'NEP 2020 explained for students and parents',
    image:
        'https://images.unsplash.com/photo-1524178232363-1fb2b075b655?crop=entropy&cs=srgb&fm=jpg&q=85&w=800',
    readTime: '6 min read',
  ),
  Article(
    id: 'art-ace-interview',
    tag: 'Placement',
    title: '5 habits that land you your first internship',
    image:
        'https://images.unsplash.com/photo-1521737604893-d14cc237f11d?crop=entropy&cs=srgb&fm=jpg&q=85&w=800',
    readTime: '5 min read',
  ),
  Article(
    id: 'art-skills-2026',
    tag: 'Skills',
    title: 'The most in-demand skills for 2026 graduates',
    image:
        'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?crop=entropy&cs=srgb&fm=jpg&q=85&w=800',
    readTime: '3 min read',
  ),
];
