import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/department_repository.dart';
import '../data/models/department_model.dart';

final regionsProvider = FutureProvider.autoDispose<List<DepartmentPublic>>((ref) async {
  return ref.watch(departmentRepositoryProvider).getRegions();
});