import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'dal_level_update_state.dart';

class DalLevelUpdateCubit extends Cubit<DalLevelUpdateState> {
  DalLevelUpdateCubit() : super(DalLevelUpdateInitial());
  void setLevel({required String title,required int lvl})async{
    SharedPreferences pref=await SharedPreferences.getInstance();
      pref.setString("DAL_Level", jsonEncode({
        "title":title,
        "Sub_title":title,
        "level":lvl
      }));
      emit(DalLevelUpdateLoaded(level: lvl,title:title));
  }
  void getLevel()async{
    SharedPreferences pref=await SharedPreferences.getInstance();
    String? level=pref.getString("DAL_Level");
    Map<String,dynamic>? getData=level==null?null:jsonDecode(level);
    if(getData!=null){
      emit(DalLevelUpdateLoaded(level: getData['level'],title:getData['title']));
    }else{
      emit(DalLevelUpdateLoaded(level: 0,title:''));
    }
  }

}
