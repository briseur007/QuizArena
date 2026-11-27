import '../../../../core/error/result.dart';
import '../../../../core/network/api_error.dart';
import '../../domain/entities/course.dart';
import '../../domain/repositories/course_repository.dart';
import '../datasources/course_local_data_source.dart';
import '../datasources/course_remote_data_source.dart';

class CourseRepositoryImpl implements CourseRepository {
  CourseRepositoryImpl({required this._remote, required this._local});

  final CourseRemoteDataSource _remote;
  final CourseLocalDataSource _local;

  @override
  Future<List<Course>?> cachedCourses() => _local.read();

  @override
  Future<Result<List<Course>>> fetchCourses() => guard(() async {
    final courses = await _remote.myCourses();
    await _local.write(courses);
    return courses;
  });

  @override
  Future<Result<Course>> joinCourse(String code) => guard(() => _remote.join(code));

  @override
  Future<Result<Course>> createCourse({required String name, required String level}) =>
      guard(() => _remote.create(name, level));
}
