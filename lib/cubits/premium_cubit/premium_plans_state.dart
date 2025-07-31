part of 'premium_plans_cubit.dart';


sealed class PlanState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PlanInitial extends PlanState {}

class PlanLoading extends PlanState {}

class PlanLoaded extends PlanState {
  final List<PlanModel> plans;
  final PremiumResponse? currentPlan;

  PlanLoaded({required this.plans, required this.currentPlan});

  @override
  List<Object?> get props => [plans, currentPlan];
}

class PlanError extends PlanState {
  final String message;

  PlanError(this.message);

  @override
  List<Object?> get props => [message];
}



