import 'package:boorusphere/data/repository/setting/entity/setting.dart';
import 'package:boorusphere/domain/repository/setting_repo.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GridSettingNotifier extends StateNotifier<int> {
  GridSettingNotifier(super.state, this.repo);

  final SettingRepo repo;

  Future<int> cycle() async {
    state = state < 2 ? state + 1 : 0;
    await repo.put(Setting.uiTimelineGrid, state);
    return state;
  }
}
