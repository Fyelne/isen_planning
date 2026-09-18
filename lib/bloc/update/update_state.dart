import 'package:equatable/equatable.dart';

import '../../services/update_checker_service.dart';

enum UpdateCheckStatus { idle, checking, upToDate, updateAvailable, error }

class UpdateState extends Equatable {
  final UpdateCheckStatus status;
  final String? currentVersion;
  final GithubRelease? latestRelease;
  final String? errorMessage;

  const UpdateState({
    this.status = UpdateCheckStatus.idle,
    this.currentVersion,
    this.latestRelease,
    this.errorMessage,
  });

  UpdateState copyWith({
    UpdateCheckStatus? status,
    String? currentVersion,
    GithubRelease? latestRelease,
    String? errorMessage,
  }) {
    return UpdateState(
      status: status ?? this.status,
      currentVersion: currentVersion ?? this.currentVersion,
      latestRelease: latestRelease ?? this.latestRelease,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, currentVersion, latestRelease, errorMessage];
}
