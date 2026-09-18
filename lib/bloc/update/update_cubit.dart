import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../services/update_checker_service.dart';
import 'update_state.dart';

class UpdateCubit extends Cubit<UpdateState> {
  UpdateCubit(this._service) : super(const UpdateState());

  final UpdateCheckerService _service;

  Future<void> checkForUpdate() async {
    emit(state.copyWith(status: UpdateCheckStatus.checking));
    try {
      final info = await PackageInfo.fromPlatform();
      final release = await _service.fetchLatestRelease();

      if (isNewerVersion(release.tagName, info.version)) {
        emit(state.copyWith(
          status: UpdateCheckStatus.updateAvailable,
          currentVersion: info.version,
          latestRelease: release,
          errorMessage: null,
        ));
      } else {
        emit(state.copyWith(
          status: UpdateCheckStatus.upToDate,
          currentVersion: info.version,
          errorMessage: null,
        ));
      }
    } on UpdateCheckException catch (error) {
      emit(state.copyWith(status: UpdateCheckStatus.error, errorMessage: error.message));
    } catch (_) {
      emit(state.copyWith(
        status: UpdateCheckStatus.error,
        errorMessage: 'Une erreur inattendue est survenue.',
      ));
    }
  }
}
