import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../models/department_model.dart';

final departmentRepositoryProvider = Provider<DepartmentRepository>((ref) {
  return DepartmentRepository(ref.watch(dioProvider));
});

class DepartmentRepository {
  final Dio _dio;

  DepartmentRepository(this._dio);

  Future<List<DepartmentPublic>> getRegions() async {
    final response = await _dio.get('/departments/public/regions');
    final data = response.data as List;
    return data.map((json) => DepartmentPublic.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<DepartmentPublic>> searchDepartments(String regionId, String search) async {
    final response = await _dio.get(
      '/departments/public/search',
      queryParameters: {
        'regionId': regionId,
        'search': search,
      },
    );
    
    final responseData = response.data;
    final List data = (responseData is Map && responseData.containsKey('data'))
        ? responseData['data'] as List
        : responseData as List;
        
    return data.map((json) => DepartmentPublic.fromJson(json as Map<String, dynamic>)).toList();
  }
}