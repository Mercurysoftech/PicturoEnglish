part of 'referal_cubit.dart';


sealed class ReferralState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ReferralInitial extends ReferralState {}

class ReferralLoading extends ReferralState {}

class ReferralLoaded extends ReferralState {
  final ReferralEarnings earnings;
  ReferralLoaded(this.earnings);

  @override
  List<Object?> get props => [earnings];
}

class ReferralError extends ReferralState {
  final String message;
  ReferralError(this.message);

  @override
  List<Object?> get props => [message];
}

