import 'package:freezed_annotation/freezed_annotation.dart';

part 'news_models.freezed.dart';
part 'news_models.g.dart';

@freezed
abstract class NewsAuthor with _$NewsAuthor {
  const factory NewsAuthor({
    required String id,
    required String firstName,
    required String lastName,
    String? avatarUrl,
  }) = _NewsAuthor;

  factory NewsAuthor.fromJson(Map<String, dynamic> json) => _$NewsAuthorFromJson(json);
}

@freezed
abstract class NewsCategory with _$NewsCategory {
  const factory NewsCategory({
    required String id,
    required String name,
    required int orderIndex,
  }) = _NewsCategory;

  factory NewsCategory.fromJson(Map<String, dynamic> json) => _$NewsCategoryFromJson(json);
}

@freezed
abstract class NewsDepartment with _$NewsDepartment {
  const factory NewsDepartment({
    required String id,
    required String name,
  }) = _NewsDepartment;

  factory NewsDepartment.fromJson(Map<String, dynamic> json) => _$NewsDepartmentFromJson(json);
}

@freezed
abstract class NewsCounts with _$NewsCounts {
  const factory NewsCounts({
    @Default(0) int comments,
    @Default(0) int likes,
    @Default(0) int dislikes,
  }) = _NewsCounts;

  factory NewsCounts.fromJson(Map<String, dynamic> json) => _$NewsCountsFromJson(json);
}

@freezed
abstract class NewsComment with _$NewsComment {
  const factory NewsComment({
    required String id,
    required String content,
    required DateTime createdAt,
    required NewsAuthor author,
  }) = _NewsComment;

  factory NewsComment.fromJson(Map<String, dynamic> json) => _$NewsCommentFromJson(json);
}

@freezed
abstract class NewsVote with _$NewsVote {
  const factory NewsVote({
    required String voteType,
    required String userId,
    required String newsId,
  }) = _NewsVote;

  factory NewsVote.fromJson(Map<String, dynamic> json) => _$NewsVoteFromJson(json);
}

@freezed
abstract class NewsArticle with _$NewsArticle {
  const factory NewsArticle({
    required String id,
    required String title,
    required String content,
    String? imageUrl,
    required String status,
    String? categoryId,
    required DateTime createdAt,
    required String authorId,
    required NewsAuthor author,
    NewsCategory? category,
    @Default([]) List<NewsDepartment> departments,
    @JsonKey(name: '_count') NewsCounts? count,
    @Default([]) List<NewsComment> comments,
    @Default([]) List<NewsVote> votes,
    @Default(0) int upvotes,
    @Default(0) int downvotes,
  }) = _NewsArticle;

  factory NewsArticle.fromJson(Map<String, dynamic> json) => _$NewsArticleFromJson(json);
}

@freezed
abstract class NewsPaginationMeta with _$NewsPaginationMeta {
  const factory NewsPaginationMeta({
    required int total,
    required int page,
    required int lastPage,
  }) = _NewsPaginationMeta;

  factory NewsPaginationMeta.fromJson(Map<String, dynamic> json) => _$NewsPaginationMetaFromJson(json);
}

@freezed
abstract class NewsPaginatedResponse with _$NewsPaginatedResponse {
  const factory NewsPaginatedResponse({
    required List<NewsArticle> data,
    required NewsPaginationMeta meta,
  }) = _NewsPaginatedResponse;

  factory NewsPaginatedResponse.fromJson(Map<String, dynamic> json) => _$NewsPaginatedResponseFromJson(json);
}