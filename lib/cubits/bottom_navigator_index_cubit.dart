import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'bottom_navigator_index_state.dart';

class BottomNavigatorIndexCubit extends Cubit<BottomNavigatorIndexState> {
  BottomNavigatorIndexCubit() : super(BottomNavigatorIndexInitial(selectedIndex: 0));
  int selectedIndex=0;
  void onChageIndex(int index ){
    selectedIndex=index;
    emit(BottomNavigatorIndexInitial(selectedIndex: selectedIndex));
  }
}
