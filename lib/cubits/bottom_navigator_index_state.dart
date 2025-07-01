part of 'bottom_navigator_index_cubit.dart';

sealed class BottomNavigatorIndexState extends Equatable {
  const BottomNavigatorIndexState();
}

final class BottomNavigatorIndexInitial extends BottomNavigatorIndexState {
  const BottomNavigatorIndexInitial({required this.selectedIndex});
  final int selectedIndex;
  @override
  List<Object> get props => [selectedIndex];
}
