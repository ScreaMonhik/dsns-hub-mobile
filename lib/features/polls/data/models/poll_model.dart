import 'package:freezed_annotation/freezed_annotation.dart';

part 'poll_model.freezed.dart';
part 'poll_model.g.dart';

@freezed
abstract class PollAuthor with _$PollAuthor {
  const factory PollAuthor({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
    String? avatarUrl,
  }) = _PollAuthor;

  factory PollAuthor.fromJson(Map<String, dynamic> json) => _$PollAuthorFromJson(json);
}

@freezed
abstract class PollDepartment with _$PollDepartment {
  const factory PollDepartment({
    required String id,
    required String name,
  }) = _PollDepartment;

  factory PollDepartment.fromJson(Map<String, dynamic> json) => _$PollDepartmentFromJson(json);
}

@freezed
abstract class PollOptionCount with _$PollOptionCount {
  const factory PollOptionCount({
    @Default(0) int votes,
  }) = _PollOptionCount;

  factory PollOptionCount.fromJson(Map<String, dynamic> json) => _$PollOptionCountFromJson(json);
}

@freezed
abstract class PollOption with _$PollOption {
  const PollOption._();

  const factory PollOption({
    required String id,
    required String text,
    required int orderIndex,
    required String pollId,
    @JsonKey(name: '_count') required PollOptionCount count,
  }) = _PollOption;

  factory PollOption.fromJson(Map<String, dynamic> json) => _$PollOptionFromJson(json);

  int get votes => count.votes;
}

@freezed
abstract class Poll with _$Poll {
  const factory Poll({
    required String id,
    required String title,
    String? description,
    required String status,
    DateTime? expiresAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? authorId,
    PollAuthor? author,
    List<PollDepartment>? departments,
    @Default([]) List<PollOption> options,
    @Default(0) int totalVotes,
    String? userVotedOptionId,
  }) = _Poll;

  factory Poll.fromJson(Map<String, dynamic> json) => _$PollFromJson(json);
}