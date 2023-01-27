import 'dart:async';


import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice_ex/directions.dart';
import 'package:google_maps_webservice_ex/places.dart';
import 'package:http/http.dart';
import 'package:location/location.dart' as LocationPlatformInterface;
import 'package:provider/provider.dart';

import '../../utils/shared_preference/shared_preference.dart';
import '../models/pick_result.dart';
import '../place_picker.dart';
import '../string_constants.dart';

class PlaceProvider extends ChangeNotifier {
  PlaceProvider(
      String apiKey,
      String? proxyBaseUrl,
      Client? httpClient,
      Map<String, dynamic> apiHeaders,
      ) {
    places = GoogleMapsPlaces(
      apiKey: apiKey,
      apiHeaders: apiHeaders as Map<String, String>?,
    );

    geocoding = GoogleMapsGeocoding(
      apiKey: apiKey,
      apiHeaders: apiHeaders as Map<String, String>?,
    );
  }

  static PlaceProvider of(BuildContext context, {bool listen = true}) =>
      Provider.of<PlaceProvider>(context, listen: listen);

  SharedPreference sharedPreference = SharedPreference();
  late GoogleMapsPlaces places;
  late GoogleMapsGeocoding geocoding;
  String? sessionToken;
  bool isOnUpdateLocationCoolDown = false;
  LocationAccuracy? desiredAccuracy;
  bool isAutoCompleteSearching = false;

  LocationPlatformInterface.Location location = LocationPlatformInterface.Location();
  LocationPlatformInterface.PermissionStatus permissionGranted = LocationPlatformInterface.PermissionStatus.denied;
  bool isLocationServiceEnabled = false;

  Future<void> updateCurrentLocation(bool forceAndroidLocationManager) async {
    isLocationServiceEnabled = await location.serviceEnabled();

    print("isLocationServiceEnabled $isLocationServiceEnabled");
    notifyListeners();
    if (!isLocationServiceEnabled) {
      isLocationServiceEnabled = await location.requestService();
      notifyListeners();
      if (!isLocationServiceEnabled) {
        return;
      }
    }
    permissionGranted = await location.hasPermission();
    notifyListeners();
    try {
      permissionGranted = await location.requestPermission();
      notifyListeners();
      if (permissionGranted == LocationPlatformInterface.PermissionStatus.granted) {
        currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: desiredAccuracy ?? LocationAccuracy.best);
        notifyListeners();
        sharedPreference.saveString(myLatitude,currentPosition!.latitude.toString());
        sharedPreference.saveString(myLongitude,currentPosition!.longitude.toString());
      } else {
        currentPosition = null;
      }
    } catch (e) {
      currentPosition = null;
    }


    notifyListeners();
  }

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;
  set currentPosition(Position? newPosition) {
    _currentPosition = newPosition;
    notifyListeners();
  }

  Timer? _debounceTimer;
  Timer? get debounceTimer => _debounceTimer;
  set debounceTimer(Timer? timer) {
    _debounceTimer = timer;
    notifyListeners();
  }

  CameraPosition? _previousCameraPosition;
  CameraPosition? get prevCameraPosition => _previousCameraPosition;
  setPrevCameraPosition(CameraPosition? prePosition) {
    _previousCameraPosition = prePosition;
  }

  CameraPosition? _currentCameraPosition;
  CameraPosition? get cameraPosition => _currentCameraPosition;
  setCameraPosition(CameraPosition? newPosition) {
    _currentCameraPosition = newPosition;
  }

  PickResult? _selectedPlace;
  PickResult? get selectedPlace => _selectedPlace;
  set selectedPlace(PickResult? result) {
    _selectedPlace = result;
    notifyListeners();
  }

  SearchingState _placeSearchingState = SearchingState.Idle;
  SearchingState get placeSearchingState => _placeSearchingState;
  set placeSearchingState(SearchingState newState) {
    _placeSearchingState = newState;
    notifyListeners();
  }

  GoogleMapController? _mapController;
  GoogleMapController? get mapController => _mapController;
  set mapController(GoogleMapController? controller) {
    _mapController = controller;
    notifyListeners();
  }

  PinState _pinState = PinState.Preparing;
  PinState get pinState => _pinState;
  set pinState(PinState newState) {
    _pinState = newState;
    notifyListeners();
  }

  bool _isSearchBarFocused = false;
  bool get isSearchBarFocused => _isSearchBarFocused;
  set isSearchBarFocused(bool focused) {
    _isSearchBarFocused = focused;
    notifyListeners();
  }

  MapType _mapType = MapType.normal;
  MapType get mapType => _mapType;
  setMapType(MapType mapType, {bool notify = false}) {
    _mapType = mapType;
    if (notify) notifyListeners();
  }

  switchMapType() {
//    _mapType = MapType.values[(_mapType.index + 1) % MapType.values.length];
    if (_mapType == MapType.satellite){
      _mapType = MapType.normal;
    }
    else{
      _mapType = MapType.satellite;
    }

      notifyListeners();
    }
}