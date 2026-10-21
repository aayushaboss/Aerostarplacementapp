import '../../mockData/mock_courses.dart' as mock;
import '../../models/course.dart';
import 'course_repository.dart';

class MockCourseRepository implements CourseRepository {
  @override
  Future<List<Course>> listCourses() async => mock.mockCourses;

  @override
  Course? getCourseById(String id) => mock.getCourseById(id);
}
