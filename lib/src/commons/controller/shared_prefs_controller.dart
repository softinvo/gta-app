import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gta_app/src/commons/repository/shared_prefs_repo.dart';
import 'package:gta_app/src/core/core.dart';

final sharedPrefsControllerPovider = Provider((ref) {
  final repo = ref.watch(sharedPrefsRepoProvider);
  return SharedPrefsController(repo: repo);
});

class SharedPrefsController {
  final SharedPrefsRepo _repo;

  SharedPrefsController({required SharedPrefsRepo repo}) : _repo = repo;

  Future<String?> getCookie() async {
    return _repo.getCookie();
  }

  FutureVoid setCookie({required String cookie}) async {
    await _repo.setCookie(cookie);
  }

  // Future<User?> getUser() async {
  //   return _repo.getCurrentUser();
  // }

  // FutureVoid setUser({required User user}) async {
  //   _repo.setCurrentUser(user);
  // }

  Future<String?> getData(key) async {
    return _repo.getData(key);
  }

  FutureVoid setData({required String key, required String cookie}) async {
    await _repo.setData(key, cookie);
  }

  FutureVoid clear() async {
    return _repo.clear();
  }
}
