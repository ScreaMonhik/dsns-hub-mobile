import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_models.freezed.dart';
part 'chat_models.g.dart';

@freezed
abstract class ChatDepartment with _$ChatDepartment {
  const factory ChatDepartment({
    required String id,
    required String name,
  }) = _ChatDepartment;

  factory ChatDepartment.fromJson(Map<String, dynamic> json) => _$ChatDepartmentFromJson(json);
}

@freezed
abstract class ChatMember with _$ChatMember {
  const factory ChatMember({
    required bool isPinned,
    int? pinOrder,
    required bool isAdmin,
  }) = _ChatMember;

  factory ChatMember.fromJson(Map<String, dynamic> json) => _$ChatMemberFromJson(json);
}

@freezed
abstract class ChatCount with _$ChatCount {
  const factory ChatCount({
    @Default(0) int members,
  }) = _ChatCount;

  factory ChatCount.fromJson(Map<String, dynamic> json) => _$ChatCountFromJson(json);
}

@freezed
abstract class ChatSender with _$ChatSender {
  const factory ChatSender({
    required String id,
    required String firstName,
    required String lastName,
    String? avatarUrl,
  }) = _ChatSender;

  factory ChatSender.fromJson(Map<String, dynamic> json) => _$ChatSenderFromJson(json);
}

@freezed
abstract class ChatReadReceipt with _$ChatReadReceipt {
  const factory ChatReadReceipt({
    required String userId,
    required DateTime readAt,
  }) = _ChatReadReceipt;

  factory ChatReadReceipt.fromJson(Map<String, dynamic> json) => _$ChatReadReceiptFromJson(json);
}

@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String content,
    required bool isDeleted,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String senderId,
    required String groupId,
    ChatSender? sender,
    @Default([]) List<ChatReadReceipt> readReceipts,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
}

@freezed
abstract class ChatGroup with _$ChatGroup {
  const factory ChatGroup({
    required String id,
    required String name,
    String? avatarUrl,
    String? departmentId,
    required DateTime createdAt,
    @Default(0) int unreadCount,
    ChatDepartment? department,
    @Default([]) List<ChatMember> members,
    @JsonKey(name: '_count') ChatCount? count,
    @Default([]) List<ChatMessage> messages,
  }) = _ChatGroup;

  factory ChatGroup.fromJson(Map<String, dynamic> json) => _$ChatGroupFromJson(json);
}

@freezed
abstract class ChatPaginationMeta with _$ChatPaginationMeta {
  const factory ChatPaginationMeta({
    required int total,
    required int page,
    required int lastPage,
    required int limit,
  }) = _ChatPaginationMeta;

  factory ChatPaginationMeta.fromJson(Map<String, dynamic> json) => _$ChatPaginationMetaFromJson(json);
}

@freezed
abstract class ChatHistoryResponse with _$ChatHistoryResponse {
  const factory ChatHistoryResponse({
    required List<ChatMessage> data,
    required ChatPaginationMeta meta,
  }) = _ChatHistoryResponse;

  factory ChatHistoryResponse.fromJson(Map<String, dynamic> json) => _$ChatHistoryResponseFromJson(json);
}