import '../../models/course.dart';
import '../api_client.dart';
import 'course_repository.dart';

/// Not wired to anything real yet — see BACKEND_API_CONTRACT.md.
class HttpCourseRepository implements CourseRepository {
  final ApiClient client;
  const HttpCourseRepository(this.client);

  @override
  Future<List<Course>> listCourses() => throw UnimplementedError('GET /courses — see BACKEND_API_CONTRACT.md');

  @override
  Course? getCourseById(String id) => throw UnimplementedError('GET /courses/{id} — needs a local cache once wired');
}
