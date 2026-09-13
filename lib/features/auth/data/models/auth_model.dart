import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_model.freezed.dart';
part 'auth_model.g.dart';

@freezed
abstract class ProfileDepartment with _$ProfileDepartment {
  const factory ProfileDepartment({
    required String id,
    String? name,
  }) = _ProfileDepartment;

  factory ProfileDepartment.fromJson(Map<String, dynamic> json) =>
      _$ProfileDepartmentFromJson(json);
}

@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String email,
    required String firstName,
    required String lastName,
    required String role,
    String? avatarUrl,
    ProfileDepartment? department,
    @Default(false) bool notifyNews,
    @Default(true) bool notifyPolls,
    @Default(true) bool notifyPollDeadlines,
    @Default(false) bool notifyDocuments,
    @Default(false) bool notifyProjects,
    @Default(true) bool notifyChats,
    @Default(true) bool notifyEmergency,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
}

extension UserProfileDisplay on UserProfile {
  String get fullName => '$lastName $firstName'.trim();
}
