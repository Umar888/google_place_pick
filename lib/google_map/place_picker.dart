import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice_ex/places.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;

import 'package:uuid/uuid.dart';

import 'autocomplete_search.dart';
import 'controllers/automcomplete_search_controller.dart';
import 'googe_map_place_picker.dart';
import 'models/circle_area.dart';
import 'models/pick_result.dart';
import 'providers/place_provider.dart';

typedef IntroModalWidgetBuilder = Widget Function(
    BuildContext context,
    Function? close,
    );

enum PinState { Preparing, Idle, Dragging }
enum SearchingState { Idle, Searching }

class PlacePicker extends StatefulWidget {
  const PlacePicker({
    Key? key,
    required this.apiKey,
    required this.mapStyle,
    this.onPlacePicked,
    required this.initialPosition,
    this.useCurrentLocation,
    this.desiredLocationAccuracy = LocationAccuracy.high,
    this.onMapCreated,
    this.hintText,
    this.searchingText,
    this.selectText,
    this.outsideOfPickAreaText,
    this.onAutoCompleteFailed,
    this.onGeocodingSearchFailed,
    this.proxyBaseUrl,
    this.httpClient,
    this.selectedPlaceWidgetBuilder,
    this.pinBuilder,
    this.introModalWidgetBuilder,
    this.autoCompleteDebounceInMilliseconds = 500,
    this.cameraMoveDebounceInMilliseconds = 750,
    this.initialMapType = MapType.normal,
    this.enableMapTypeButton = true,
    this.enableMyLocationButton = true,
    this.myLocationButtonCooldown = 10,
    this.usePinPointingSearch = true,
    this.usePlaceDetailSearch = false,
    this.autocompleteOffset,
    this.autocompleteRadius,
    this.autocompleteLanguage,
    this.autocompleteComponents,
    this.autocompleteTypes,
    this.strictbounds,
    this.region,
    this.pickArea,
    this.selectInitialPosition = false,
    this.resizeToAvoidBottomInset = true,
    this.initialSearchString,
    this.searchForInitialValue = false,
    this.forceAndroidLocationManager = false,
    this.forceSearchOnZoomChanged = false,
    this.automaticallyImplyAppBarLeading = true,
    this.autocompleteOnTrailingWhitespace = false,
    this.hidePlaceDetailsWhenDraggingPin = true,
    this.onTapBack,
    this.onCameraMoveStarted,
    this.onCameraMove,
    this.onCameraIdle,
  }) : super(key: key);

  final String apiKey;
  final String mapStyle;

  final LatLng initialPosition;
  final bool? useCurrentLocation;
  final LocationAccuracy desiredLocationAccuracy;

  final MapCreatedCallback? onMapCreated;

  final String? hintText;
  final String? searchingText;
  final String? selectText;
  final String? outsideOfPickAreaText;

  final ValueChanged<String>? onAutoCompleteFailed;
  final ValueChanged<String>? onGeocodingSearchFailed;
  final int autoCompleteDebounceInMilliseconds;
  final int cameraMoveDebounceInMilliseconds;

  final MapType initialMapType;
  final bool enableMapTypeButton;
  final bool enableMyLocationButton;
  final int myLocationButtonCooldown;

  final bool usePinPointingSearch;
  final bool usePlaceDetailSearch;

  final num? autocompleteOffset;
  final num? autocompleteRadius;
  final String? autocompleteLanguage;
  final List<String>? autocompleteTypes;
  final List<Component>? autocompleteComponents;
  final bool? strictbounds;
  final String? region;
  final CircleArea? pickArea;
  final bool resizeToAvoidBottomInset;
  final bool selectInitialPosition;
  final ValueChanged<PickResult>? onPlacePicked;
  final SelectedPlaceWidgetBuilder? selectedPlaceWidgetBuilder;
  final PinBuilder? pinBuilder;
  final IntroModalWidgetBuilder? introModalWidgetBuilder;
  final String? proxyBaseUrl;
  final BaseClient? httpClient;
  final String? initialSearchString;
  final bool searchForInitialValue;
  final bool forceAndroidLocationManager;
  final bool forceSearchOnZoomChanged;
  final bool automaticallyImplyAppBarLeading;
  final bool autocompleteOnTrailingWhitespace;
  final bool hidePlaceDetailsWhenDraggingPin;
  final VoidCallback? onTapBack;
  final Function(PlaceProvider)? onCameraMoveStarted;
  final CameraPositionCallback? onCameraMove;
  final Function(PlaceProvider)? onCameraIdle;


  @override
  _PlacePickerState createState() => _PlacePickerState();
}

class _PlacePickerState extends State<PlacePicker> {
  GlobalKey appBarKey = GlobalKey();
  Future<PlaceProvider>? _futureProvider;
  PlaceProvider? provider;
  SearchBarController searchBarController = SearchBarController();
  bool showintroModal = true;

  @override
  void initState() {
    super.initState();

    _futureProvider = _initPlaceProvider();
  }

  @override
  void dispose() {
    searchBarController.dispose();

    super.dispose();
  }

  Future<PlaceProvider> _initPlaceProvider() async {
    final headers = await const GoogleApiHeaders().getHeaders();
    final provider = PlaceProvider(
      widget.apiKey,
      widget.proxyBaseUrl,
      widget.httpClient,
      headers,
    );
    provider.sessionToken = const Uuid().v4();
    provider.desiredAccuracy = widget.desiredLocationAccuracy;
    provider.setMapType(widget.initialMapType);

    return provider;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () {
          searchBarController.clearOverlay();
          return Future.value(true);
        },
        child: FutureBuilder<PlaceProvider>(
          future: _futureProvider,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              provider = snapshot.data;

              return MultiProvider(
                providers: [
                  ChangeNotifierProvider<PlaceProvider>.value(value: provider!),
                ],
                child: Stack(children: [
                  Scaffold(
                    key: ValueKey<int>(provider.hashCode),
                    resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
                    extendBodyBehindAppBar: true,
                    appBar: AppBar(
                      key: appBarKey,
                      automaticallyImplyLeading: false,
                      iconTheme: Theme.of(context).iconTheme,
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      titleSpacing: 0.0,
                      title: _buildSearchBar(context),
                    ),
                    body: _buildMapWithLocation(),
                  ),
                  _buildIntroModal(context),
                ]),
              );
            }

            final children = <Widget>[];
            if (snapshot.hasError) {
              children.addAll([
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).errorColor,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text('Error: ${snapshot.error}'),
                )
              ]);
            } else {
              children.add(const CircularProgressIndicator());
            }

            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: children,
                ),
              ),
            );
          },
        )
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Row(
      children: <Widget>[
        /*widget.automaticallyImplyAppBarLeading ||
            widget.onTapBack != null
            ? IconButton(
            onPressed: () {
              if(!showintroModal || widget.introModalWidgetBuilder == null) {
                if(widget.onTapBack != null) {
                  widget.onTapBack!();
                  return;
                }
                Navigator.maybePop(context);
              }
            },
            icon: Icon(
              Platform.isIOS ? Icons.arrow_back_ios : Icons.arrow_back,
            ),
            color: Colors.black.withAlpha(128),
            padding: EdgeInsets.zero)
            : const SizedBox(width: 15),*/
        const SizedBox(width: 10),
        Expanded(
          child: AutoCompleteSearch(
              appBarKey: appBarKey,
              searchBarController: searchBarController,
              sessionToken: provider!.sessionToken,
              hintText: widget.hintText,


              searchingText: widget.searchingText,
              debounceMilliseconds: widget.autoCompleteDebounceInMilliseconds,
              onPicked: (prediction) {
                _pickPrediction(prediction);
              },
              onSearchFailed: (status) {
                if (widget.onAutoCompleteFailed != null) {
                  widget.onAutoCompleteFailed!(status);
                }
              },
              autocompleteOffset: widget.autocompleteOffset,
              autocompleteRadius: widget.autocompleteRadius,
              autocompleteLanguage: widget.autocompleteLanguage,
              autocompleteComponents: widget.autocompleteComponents,
              autocompleteTypes: widget.autocompleteTypes,
              strictbounds: widget.strictbounds,
              region: widget.region,
              initialSearchString: widget.initialSearchString,
              searchForInitialValue: widget.searchForInitialValue,
              autocompleteOnTrailingWhitespace: widget.autocompleteOnTrailingWhitespace),
        ),
        const SizedBox(width: 5),
      ],
    );
  }

  _pickPrediction(Prediction prediction) async {
    provider!.placeSearchingState = SearchingState.Searching;

    final PlacesDetailsResponse response = await provider!.places.getDetailsByPlaceId(
      prediction.placeId!,
      sessionToken: provider!.sessionToken,
      language: widget.autocompleteLanguage,
    );

    if (response.errorMessage?.isNotEmpty == true || response.status == "REQUEST_DENIED") {
      if (widget.onAutoCompleteFailed != null) {
        widget.onAutoCompleteFailed!(response.status);
      }
      return;
    }

    provider!.selectedPlace = PickResult.fromPlaceDetailResult(response.result!);

    // Prevents searching again by camera movement.
    provider!.isAutoCompleteSearching = true;

    await _moveTo(provider!.selectedPlace!.geometry!.location.lat, provider!.selectedPlace!.geometry!.location.lng);

    provider!.placeSearchingState = SearchingState.Idle;
  }

  _moveTo(double latitude, double longitude) async {
    GoogleMapController? controller = provider!.mapController;
    if (controller == null) return;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(latitude, longitude),
          zoom: 16,
        ),
      ),
    );
  }

  _moveToCurrentPosition() async {
    if (provider!.currentPosition != null) {
      await _moveTo(provider!.currentPosition!.latitude, provider!.currentPosition!.longitude);
    }
  }

  Widget _buildMapWithLocation() {
    if (widget.useCurrentLocation != null && widget.useCurrentLocation!) {
      return FutureBuilder(
          future: provider!.updateCurrentLocation(widget.forceAndroidLocationManager),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CupertinoActivityIndicator());
            } else {
              if (provider!.currentPosition == null) {
                return _buildMap(widget.initialPosition);
              } else {
                return _buildMap(widget.initialPosition);

//                return _buildMap(LatLng(provider!.currentPosition!.latitude, provider!.currentPosition!.longitude));
              }
            }
          });
    } else {
      return FutureBuilder(
        future: Future.delayed(const Duration(milliseconds: 0)),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return _buildMap(widget.initialPosition);
          }
        },
      );
    }
  }

  Widget _buildMap(LatLng initialTarget) {
    return GoogleMapPlacePicker(
      initialTarget: initialTarget,
      mapStyle: widget.mapStyle,
      appBarKey: appBarKey,
      selectedPlaceWidgetBuilder: widget.selectedPlaceWidgetBuilder,
      pinBuilder: widget.pinBuilder,
      onSearchFailed: widget.onGeocodingSearchFailed,
      debounceMilliseconds: widget.cameraMoveDebounceInMilliseconds,
      enableMapTypeButton: widget.enableMapTypeButton,
      enableMyLocationButton: widget.enableMyLocationButton,
      usePinPointingSearch: widget.usePinPointingSearch,
      usePlaceDetailSearch: widget.usePlaceDetailSearch,
      onMapCreated: widget.onMapCreated,
      selectInitialPosition: widget.selectInitialPosition,
      language: widget.autocompleteLanguage,
      pickArea: widget.pickArea,
      forceSearchOnZoomChanged: widget.forceSearchOnZoomChanged,
      hidePlaceDetailsWhenDraggingPin: widget.hidePlaceDetailsWhenDraggingPin,
      selectText: widget.selectText,
      outsideOfPickAreaText: widget.outsideOfPickAreaText,
      onToggleMapType: () {
        provider!.switchMapType();
        if(provider!.mapType != MapType.satellite){
        rootBundle.loadString(widget.mapStyle).then((string) {
            provider!.mapController!.setMapStyle(widget.mapStyle);
        });
        }
      },
      onMyLocation: () async {
        // Prevent to click many times in short period.
        if (provider!.isOnUpdateLocationCoolDown == false) {
          provider!.isOnUpdateLocationCoolDown = true;
          Timer(Duration(seconds: widget.myLocationButtonCooldown), () {
            provider!.isOnUpdateLocationCoolDown = false;
          });
          await provider!.updateCurrentLocation(widget.forceAndroidLocationManager);
          await _moveToCurrentPosition();
        }
      },
      onMoveStart: () {
        searchBarController.reset();
      },
      onPlacePicked: widget.onPlacePicked,
      onCameraMoveStarted: widget.onCameraMoveStarted,
      onCameraMove: widget.onCameraMove,
      onCameraIdle: widget.onCameraIdle,
    );
  }

  Widget _buildIntroModal(BuildContext context) {
    return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return showintroModal && widget.introModalWidgetBuilder != null
              ? Stack(children: [
            const Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              left: 0,
              child: Material(
                type: MaterialType.canvas,
                color: Color.fromARGB(128, 0, 0, 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                child: ClipRect(),
              ),
            ),
            widget.introModalWidgetBuilder!(context, () {
              setState(() {
                showintroModal = false;
              });
            })
          ])
              : Container();
        }
    );
  }
}
