import 'package:dio/dio.dart';

import '../../../../core/network/paginated.dart';
import '../../domain/entities/course.dart';
import '../models/course_model.dart';

class CourseRemoteDataSource {
  CourseRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<Course>> myCourses() async {
    final res = await _dio.get<Map<String, dynamic>>('/courses', queryParameters: {'limit': 50});
    return Paginated.fromJson(res.data!, CourseModel.fromJson).items;
  }

  Future<Course> join(String code) async {
    final res = await _dio.post<Map<String, dynamic>>('/courses/join', data: {'code': code});
    return CourseModel.fromJson(res.data!);
  }

  Future<Course> create(String name, String level) async {
    final res = await _dio.post<Map<String, dynamic>>('/courses', data: {'name': name, 'level': level});
    return CourseModel.fromJson(res.data!);
  }
}
