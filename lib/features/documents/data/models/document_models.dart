import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_models.freezed.dart';
part 'document_models.g.dart';

@freezed
abstract class DocumentAuthor with _$DocumentAuthor {
  const factory DocumentAuthor({
    required String id,
    String? firstName,
    String? lastName,
    String? avatarUrl,
  }) = _DocumentAuthor;

  factory DocumentAuthor.fromJson(Map<String, dynamic> json) => _$DocumentAuthorFromJson(json);
}

@freezed
abstract class DocumentDepartment with _$DocumentDepartment {
  const factory DocumentDepartment({
    required String id,
    String? name,
  }) = _DocumentDepartment;

  factory DocumentDepartment.fromJson(Map<String, dynamic> json) => _$DocumentDepartmentFromJson(json);
}

@freezed
abstract class DocumentModel with _$DocumentModel {
  const factory DocumentModel({
    required String id,
    String? title,
    String? description,
    String? fileUrl,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authorId,
    DocumentAuthor? author,
    @Default([]) List<DocumentDepartment> departments,
  }) = _DocumentModel;

  factory DocumentModel.fromJson(Map<String, dynamic> json) => _$DocumentModelFromJson(json);
}

@freezed
abstract class DocumentPaginationMeta with _$DocumentPaginationMeta {
  const factory DocumentPaginationMeta({
    @Default(0) int total,
    @Default(1) int page,
    @Default(1) int lastPage,
    @Default(10) int limit,
  }) = _DocumentPaginationMeta;

  factory DocumentPaginationMeta.fromJson(Map<String, dynamic> json) => _$DocumentPaginationMetaFromJson(json);
}

@freezed
abstract class DocumentPaginatedResponse with _$DocumentPaginatedResponse {
  const factory DocumentPaginatedResponse({
    @Default([]) List<DocumentModel> data,
    DocumentPaginationMeta? meta,
  }) = _DocumentPaginatedResponse;

  factory DocumentPaginatedResponse.fromJson(Map<String, dynamic> json) => _$DocumentPaginatedResponseFromJson(json);
}