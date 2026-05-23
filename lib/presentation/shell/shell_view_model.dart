import 'package:flutter/foundation.dart';

import '../../core/navigation/app_tab.dart';

class ShellViewModel extends ChangeNotifier {
  AppTab _currentTab = AppTab.home;

  AppTab get currentTab => _currentTab;
  int get currentIndex => _currentTab.index;

  void selectTab(AppTab tab) {
    if (_currentTab == tab) return;
    _currentTab = tab;
    notifyListeners();
  }

  void selectIndex(int index) {
    selectTab(AppTab.valuesOrdered[index]);
  }
}
