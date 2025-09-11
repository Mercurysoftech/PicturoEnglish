// avatar_cubit.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

import '../../responses/avatar_response.dart';

part 'get_avatar_state.dart';



class AvatarCubit extends Cubit<AvatarState> {
  AvatarCubit() : super(AvatarInitial());

  Future<void> loadAvatar() async {
    emit(AvatarLoading());
    try{
    final apiService = await ApiService.create();
    final profile = await apiService.fetchProfileDetails();

    if (profile.user.avatarId == null || profile.user.avatarId == 0) {
      throw Exception('Using default avatar');
    }

    final avatarResponse = await apiService.fetchAvatars();
    final avatar = avatarResponse.data.firstWhere(
          (a) => a.id == profile.user.avatarId,
      orElse: () => throw Exception('Avatar not found'),
    );

    final avatarUrl= 'http://picturoenglish.com/admin/${avatar.avatarUrl}';

      final imageProvider = CachedNetworkImageProvider(avatarUrl);
      emit(AvatarLoaded(imageProvider));
    } catch (e) {
      emit(AvatarError('Error loading avatar: ${e.toString()}'));
    }
  }

  /// Utility method for fallback image
  ImageProvider getFallbackAvatarImage() {
    return const AssetImage('assets/avatar2.png');
  }
}
