import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? partnerId;

  const UserEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.partnerId,
  });

  @override
  List<Object?> get props => [id, email, displayName, photoUrl, partnerId];
}
