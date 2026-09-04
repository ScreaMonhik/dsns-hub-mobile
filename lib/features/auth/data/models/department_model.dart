import 'package:freezed_annotation/freezed_annotation.dart';

part 'department_model.freezed.dart';
part 'department_model.g.dart';

@freezed
abstract class DepartmentPublic with _$DepartmentPublic {
  const factory DepartmentPublic({
    required String id,
    required String name,
  }) = _DepartmentPublic;

  factory DepartmentPublic.fromJson(Map<String, dynamic> json) => _$DepartmentPublicFromJson(json);
}