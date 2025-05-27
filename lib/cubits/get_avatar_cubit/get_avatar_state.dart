part of 'get_avatar_cubit.dart';


abstract class AvatarState extends Equatable {
  const AvatarState();

  @override
  List<Object?> get props => [];
}

class AvatarInitial extends AvatarState {}

class AvatarLoading extends AvatarState {}

class AvatarLoaded extends AvatarState {
  final ImageProvider imageProvider;

  const AvatarLoaded(this.imageProvider);

  @override
  List<Object?> get props => [imageProvider];
}

class AvatarError extends AvatarState {
  final String message;

  const AvatarError(this.message);

  @override
  List<Object?> get props => [message];
}
