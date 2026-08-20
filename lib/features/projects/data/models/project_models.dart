import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_models.freezed.dart';
part 'project_models.g.dart';

@freezed
abstract class ProjectAuthor with _$ProjectAuthor {
  const factory ProjectAuthor({
    required String id,
    String? firstName,
    String? lastName,
    String? avatarUrl,
  }) = _ProjectAuthor;

  factory ProjectAuthor.fromJson(Map<String, dynamic> json) => _$ProjectAuthorFromJson(json);
}

@freezed
abstract class ProjectDepartment with _$ProjectDepartment {
  const factory ProjectDepartment({
    required String id,
    String? name,
  }) = _ProjectDepartment;

  factory ProjectDepartment.fromJson(Map<String, dynamic> json) => _$ProjectDepartmentFromJson(json);
}

@freezed
abstract class ProjectComment with _$ProjectComment {
  const factory ProjectComment({
    required String id,
    String? content,
    DateTime? createdAt,
    String? authorId,
    String? projectId,
    ProjectAuthor? author,
  }) = _ProjectComment;

  factory ProjectComment.fromJson(Map<String, dynamic> json) => _$ProjectCommentFromJson(json);
}

@freezed
abstract class ProjectCount with _$ProjectCount {
  const factory ProjectCount({
    @Default(0) int comments,
  }) = _ProjectCount;

  factory ProjectCount.fromJson(Map<String, dynamic> json) => _$ProjectCountFromJson(json);
}

@freezed
abstract class ProjectModel with _$ProjectModel {
  const factory ProjectModel({
    required String id,
    String? title,
    String? description,
    String? fileUrl,
    String? status,
    @Default(0) int upvotes,
    @Default(0) int downvotes,
    String? currentUserVote,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authorId,
    ProjectAuthor? author,
    @Default([]) List<ProjectDepartment> departments,
    @Default([]) List<ProjectComment> comments,
    @JsonKey(name: '_count') ProjectCount? count,
  }) = _ProjectModel;

  factory ProjectModel.fromJson(Map<String, dynamic> json) => _$ProjectModelFromJson(json);
}

@freezed
abstract class ProjectPaginationMeta with _$ProjectPaginationMeta {
  const factory ProjectPaginationMeta({
    @Default(0) int total,
    @Default(1) int page,
    @Default(1) int lastPage,
    @Default(10) int limit,
  }) = _ProjectPaginationMeta;

  factory ProjectPaginationMeta.fromJson(Map<String, dynamic> json) => _$ProjectPaginationMetaFromJson(json);
}

@freezed
abstract class ProjectPaginatedResponse with _$ProjectPaginatedResponse {
  const factory ProjectPaginatedResponse({
    @Default([]) List<ProjectModel> data,
    ProjectPaginationMeta? meta,
  }) = _ProjectPaginatedResponse;

  factory ProjectPaginatedResponse.fromJson(Map<String, dynamic> json) => _$ProjectPaginatedResponseFromJson(json);
}