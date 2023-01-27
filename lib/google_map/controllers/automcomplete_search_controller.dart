import 'package:flutter/cupertino.dart';

import '../autocomplete_search.dart';

class SearchBarController extends ChangeNotifier {
  late AutoCompleteSearchState _autoCompleteSearch;

  attach(AutoCompleteSearchState searchWidget) {
    _autoCompleteSearch = searchWidget;
  }

  clear() {
    _autoCompleteSearch.clearText();
  }

  reset() {
    _autoCompleteSearch.resetSearchBar();
  }

  clearOverlay() {
    _autoCompleteSearch.clearOverlay();
  }
}