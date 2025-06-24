part of 'dal_level_update_cubit.dart';

sealed class DalLevelUpdateState extends Equatable {
  const DalLevelUpdateState();
}

final class DalLevelUpdateInitial extends DalLevelUpdateState {
  @override
  List<Object> get props => [];
}
final class DalLevelUpdateLoaded extends DalLevelUpdateState {
  const DalLevelUpdateLoaded({required this.level,required this.title});
  final String title;
  final int level;
  @override
  List<Object> get props => [title,level];
}
