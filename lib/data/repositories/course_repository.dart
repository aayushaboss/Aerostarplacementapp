import '../../models/course.dart';

abstract class CourseRepository {
  Future<List<Course>> listCourses();
  Course? getCourseById(String id);
}
