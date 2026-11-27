import '../../../../core/storage/json_cache.dart';
import '../../domain/entities/course.dart';
import '../models/course_model.dart';

/// Cache de la liste des cours (F9 : visible au démarrage hors ligne).
class CourseLocalDataSource {
  CourseLocalDataSource(this._cache);

  final JsonCache _cache;
  static const _key = 'cache.courses';

  Future<List<Course>?> read() async {
    final json = await _cache.read<List<dynamic>>(_key);
    return json?.cast<Map<String, dynamic>>().map(CourseModel.fromJson).toList();
  }

  Future<void> write(List<Course> courses) => _cache.write(_key, courses.map(CourseModel.toJson).toList());
}
