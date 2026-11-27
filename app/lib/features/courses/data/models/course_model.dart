import '../../domain/entities/course.dart';

abstract final class CourseModel {
  static Course fromJson(Map<String, dynamic> json) => Course(
    id: json['id'] as String,
    name: json['name'] as String,
    level: json['level'] as String? ?? '',
    teacherName: json['teacherName'] as String? ?? '',
    studentCount: (json['studentCount'] as num?)?.toInt() ?? 0,
    quizCount: (json['quizCount'] as num?)?.toInt() ?? 0,
    code: json['code'] as String?,
  );

  static Map<String, dynamic> toJson(Course c) => {
    'id': c.id,
    'name': c.name,
    'level': c.level,
    'teacherName': c.teacherName,
    'studentCount': c.studentCount,
    'quizCount': c.quizCount,
    'code': ?c.code,
  };
}
