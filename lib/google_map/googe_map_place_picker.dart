import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice_ex/places.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import 'package:turing_demo/google_map/components/address_detail.dart';
import 'dart:math' as math;

import 'components/animated_pin.dart';
import 'components/app_image.dart';
import 'components/floating_card.dart';
import 'models/circle_area.dart';
import 'models/pick_result.dart';
import 'place_picker.dart';
import 'providers/place_provider.dart';

typedef SelectedPlaceWidgetBuilder = Widget Function(
    BuildContext context,
    PickResult? selectedPlace,
    SearchingState state,
    bool isSearchBarFocused,
    );

typedef PinBuilder = Widget Function(
    BuildContext context,
    PinState state,
    );

class GoogleMapPlacePicker extends StatelessWidget {
  const GoogleMapPlacePicker({
    Key? key,
    required this.initialTarget,
    required this.mapStyle,
    required this.appBarKey,
    this.selectedPlaceWidgetBuilder,
    this.pinBuilder,
    this.onSearchFailed,
    this.onMoveStart,
    this.onMapCreated,
    this.debounceMilliseconds,
    this.enableMapTypeButton,
    this.enableMyLocationButton,
    this.onToggleMapType,
    this.onMyLocation,
    this.onPlacePicked,
    this.usePinPointingSearch,
    this.usePlaceDetailSearch,
    this.selectInitialPosition,
    this.language,
    this.pickArea,
    this.forceSearchOnZoomChanged,
    this.hidePlaceDetailsWhenDraggingPin,
    this.onCameraMoveStarted,
    this.onCameraMove,
    this.onCameraIdle,
    this.selectText,
    this.outsideOfPickAreaText,
  }) : super(key: key);

  final LatLng initialTarget;
  final GlobalKey appBarKey;

  final SelectedPlaceWidgetBuilder? selectedPlaceWidgetBuilder;
  final PinBuilder? pinBuilder;

  final ValueChanged<String>? onSearchFailed;
  final VoidCallback? onMoveStart;
  final MapCreatedCallback? onMapCreated;
  final VoidCallback? onToggleMapType;
  final VoidCallback? onMyLocation;
  final ValueChanged<PickResult>? onPlacePicked;

  final int? debounceMilliseconds;
  final bool? enableMapTypeButton;
  final bool? enableMyLocationButton;

  final bool? usePinPointingSearch;
  final bool? usePlaceDetailSearch;

  final bool? selectInitialPosition;

  final String? language;
  final String? mapStyle;
  final CircleArea? pickArea;

  final bool? forceSearchOnZoomChanged;
  final bool? hidePlaceDetailsWhenDraggingPin;

  /// GoogleMap pass-through events:
  final Function(PlaceProvider)? onCameraMoveStarted;
  final CameraPositionCallback? onCameraMove;
  final Function(PlaceProvider)? onCameraIdle;

  // strings
  final String? selectText;
  final String? outsideOfPickAreaText;

  _searchByCameraLocation(PlaceProvider provider) async {
    // We don't want to search location again if camera location is changed by zooming in/out.
    if (forceSearchOnZoomChanged == false && provider.prevCameraPosition != null && provider.prevCameraPosition!.target.latitude == provider.cameraPosition!.target.latitude && provider.prevCameraPosition!.target.longitude == provider.cameraPosition!.target.longitude) {
      provider.placeSearchingState = SearchingState.Idle;
      return;
    }

    provider.placeSearchingState = SearchingState.Searching;

    final GeocodingResponse response = await provider.geocoding.searchByLocation(
      Location(lat: provider.cameraPosition!.target.latitude, lng: provider.cameraPosition!.target.longitude),
      language: language,
    );

    if (response.errorMessage?.isNotEmpty == true || response.status == "REQUEST_DENIED") {
      if (onSearchFailed != null) {
        onSearchFailed!(response.status);
      }
      provider.placeSearchingState = SearchingState.Idle;
      return;
    }

    if (usePlaceDetailSearch!) {
      final PlacesDetailsResponse detailResponse = await provider.places.getDetailsByPlaceId(
        response.results[0].placeId,
        language: language,
      );

      if (detailResponse.errorMessage?.isNotEmpty == true || detailResponse.status == "REQUEST_DENIED") {
        if (onSearchFailed != null) {
          onSearchFailed!(detailResponse.status);
        }
        provider.placeSearchingState = SearchingState.Idle;
        return;
      }

      provider.selectedPlace = PickResult.fromPlaceDetailResult(detailResponse.result!);
    } else {
      provider.selectedPlace = PickResult.fromGeocodingResult(response.results[0]);
    }

    provider.placeSearchingState = SearchingState.Idle;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        _buildGoogleMap(context),
        _buildPin(),
        _buildFloatingCard(),
        _buildMapIcons(context),
      ],
    );
  }

  Widget _buildGoogleMap(BuildContext context) {
    return Selector<PlaceProvider, MapType>(
        selector: (_, provider) => provider.mapType,
        builder: (_, data, __) {
          PlaceProvider provider = PlaceProvider.of(context, listen: false);
          CameraPosition initialCameraPosition = CameraPosition(target: initialTarget, zoom: 15);

          return GoogleMap(
            myLocationButtonEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            onTap: (latlng){

            },

            initialCameraPosition: initialCameraPosition,
            mapType: data,
            myLocationEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              provider.mapController = controller;
              rootBundle.loadString(mapStyle!).then((string) {
                provider.mapController!.setMapStyle(string);
              });
              provider.setCameraPosition(null);
              provider.pinState = PinState.Idle;


              // When select initialPosition set to true.
              if (selectInitialPosition!) {
                provider.setCameraPosition(initialCameraPosition);
                _searchByCameraLocation(provider);
              }
            },
            onCameraIdle: () {
              if (provider.isAutoCompleteSearching) {
                provider.isAutoCompleteSearching = false;
                provider.pinState = PinState.Idle;
                provider.placeSearchingState = SearchingState.Idle;
                return;
              }

              // Perform search only if the setting is to true.
              if (usePinPointingSearch!) {
                // Search current camera location only if camera has moved (dragged) before.
                if (provider.pinState == PinState.Dragging) {
                  // Cancel previous timer.
                  if (provider.debounceTimer?.isActive ?? false) {
                    provider.debounceTimer!.cancel();
                  }
                  provider.debounceTimer = Timer(Duration(milliseconds: debounceMilliseconds!), () {
                    _searchByCameraLocation(provider);
                  });
                }
              }

              provider.pinState = PinState.Idle;

              if(onCameraIdle != null) {
                onCameraIdle!(provider);
              }
            },
            onCameraMoveStarted: () {
              if(onCameraMoveStarted != null) {
                onCameraMoveStarted!(provider);
              }

              provider.setPrevCameraPosition(provider.cameraPosition);

              // Cancel any other timer.
              provider.debounceTimer?.cancel();

              // Update state, dismiss keyboard and clear text.
              provider.pinState = PinState.Dragging;

              // Begins the search state if the hide details is enabled
              if (hidePlaceDetailsWhenDraggingPin!) {
                provider.placeSearchingState = SearchingState.Searching;
              }

              onMoveStart!();
            },
            onCameraMove: (CameraPosition position) {
              provider.setCameraPosition(position);
              if(onCameraMove != null) {
                onCameraMove!(position);
              }
            },
            gestureRecognizers: Set()..add(Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer())),
          );
        });
  }

  Widget _buildPin() {
    return Center(
      child: Selector<PlaceProvider, Tuple2<PinState, PickResult?>>(
        selector: (_, provider) => Tuple2(provider.pinState,provider.selectedPlace),
        builder: (context, state, __) {
          if (pinBuilder == null) {
            return _defaultPinBuilder(context, state.item1,state.item2);
          } else {
            return Builder(builder: (builderContext) => pinBuilder!(builderContext, state.item1));
          }
        },
      ),
    );
  }

  Widget _defaultPinBuilder(BuildContext context, PinState state,PickResult? pickResult) {
    if (state == PinState.Preparing) {
      return Container();
    } else if (state == PinState.Idle) {
      return Stack(
        children: <Widget>[
          InkWell(
            onTap: (){
              showInformation(context,pickResult);
            },
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const <Widget>[
                  Icon(Icons.place, size: 36, color: Colors.orange),
                  SizedBox(height: 42),
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      );
    } else {
      return Stack(
        children: <Widget>[
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AnimatedPin(child: const Icon(Icons.place, size: 36, color: Colors.orange)),
                const SizedBox(height: 42),
              ],
            ),
          ),
          Center(
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      );
    }
  }

  showInformation(BuildContext context,PickResult? pickResult){
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AlertDialog(
              contentPadding: EdgeInsets.zero,
              clipBehavior: Clip.hardEdge,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)
              ),

              content: pickResult == null?
              SizedBox(
                      height: MediaQuery.of(context).size.height*0.3,
                      child: const Center(child: CircularProgressIndicator(color: Colors.red))):
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0,horizontal: 15),
                child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            const Text("Address Detail",
                                style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18)),
                            const SizedBox(height: 10,),
                            Divider(color: Colors.grey.shade500,
                              height: 1,),
                            const SizedBox(height: 10,),
                            Row(
                              children: [
                                AppImage(
                                  link: pickResult.icon??"",
                                  height: 24,
                                ),
                                const SizedBox(width: 5),
                                Text(pickResult.name??"",
                                style: const TextStyle(
                                  fontSize:14,
                                  fontWeight: FontWeight.bold
                                ),),
                              ],
                            ),
                            const SizedBox(height: 10,),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Full Address:",
                                  style: TextStyle(
                                      fontSize:14,
                                      fontWeight: FontWeight.bold
                                  ),),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(pickResult.formattedAddress??"",
                                    style: const TextStyle(
                                      fontSize:14,
                                    ),),
                                ),
                              ],
                            ),
                            pickResult.internationalPhoneNumber != null &&
                                pickResult.internationalPhoneNumber!.isNotEmpty?
                            const SizedBox(height: 10,):const SizedBox.shrink(),
                            pickResult.internationalPhoneNumber != null &&
                                pickResult.internationalPhoneNumber!.isNotEmpty?
                            Row(
                              children: [
                                const Text("Phone:",
                                  style: TextStyle(
                                    fontSize:14,
                                    fontWeight: FontWeight.bold
                                ),),
                                const SizedBox(width: 3),
                                Text(pickResult.internationalPhoneNumber??"",
                                  style: const TextStyle(
                                    fontSize:14,
                                ),),
                              ],
                            ):const SizedBox.shrink(),
                            pickResult.website != null &&
                                pickResult.website!.isNotEmpty?
                            const SizedBox(height: 10,):const SizedBox.shrink(),
                            pickResult.website != null &&
                                pickResult.website!.isNotEmpty?
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Website:",
                                  style: TextStyle(
                                    fontSize:14,
                                    fontWeight: FontWeight.bold
                                ),),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(pickResult.website??"",
                                    style: const TextStyle(
                                      fontSize:14,
                                  ),),
                                ),
                              ],
                            ):const SizedBox.shrink(),
                            const SizedBox(height: 10,),
                            MaterialButton(
                              textColor:Colors.white,
                              color: Colors.red,
                              elevation: 10,

                              child: const Text(
                                "Open Details",
                                style: TextStyle(
                                    fontWeight: FontWeight.w300
                                ),),
                              onPressed: () {
                                Navigator.of(context).push(
                                  CupertinoPageRoute(
                                    builder: (context) =>
                                        AddressDetail(
                                          pickResult:  pickResult
                                        ),
                                  ),
                                );
                              },
                            ),
                          ]
                      ),
              )

            ),
          );
        }
    );
  }

  Widget _buildFloatingCard() {
    return Selector<PlaceProvider, Tuple4<PickResult?, SearchingState, bool, PinState>>(
      selector: (_, provider) => Tuple4(provider.selectedPlace, provider.placeSearchingState, provider.isSearchBarFocused, provider.pinState),
      builder: (context, data, __) {
        if ((data.item1 == null && data.item2 == SearchingState.Idle) || data.item3 == true || data.item4 == PinState.Dragging && hidePlaceDetailsWhenDraggingPin!) {
          return Container();
        } else {
          if (selectedPlaceWidgetBuilder == null) {
            return _defaultPlaceWidgetBuilder(context, data.item1, data.item2);
          }
          else {
            return Builder(builder: (builderContext) => selectedPlaceWidgetBuilder!(builderContext, data.item1, data.item2, data.item3));
          }
        }
      },
    );
  }

  Widget _defaultPlaceWidgetBuilder(BuildContext context, PickResult? data, SearchingState state) {
    return FloatingCard(
      bottomPosition: MediaQuery.of(context).size.height * 0.1,
      leftPosition: MediaQuery.of(context).size.width * 0.15,
      rightPosition: MediaQuery.of(context).size.width * 0.15,
      width: MediaQuery.of(context).size.width * 0.7,
      borderRadius: BorderRadius.circular(12.0),
      elevation: 4.0,
      color: Theme.of(context).cardColor,
      child: state == SearchingState.Searching ? _buildLoadingIndicator() : _buildSelectionDetails(context, data!),
    );
  }

  Widget _buildLoadingIndicator() {
    return const SizedBox(
      height: 48,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildSelectionDetails(BuildContext context, PickResult result) {
    bool canBePicked = pickArea == null || pickArea!.radius <= 0 || Geolocator.distanceBetween(
        pickArea!.center.latitude,
        pickArea!.center.longitude,
        result.geometry!.location.lat,
        result.geometry!.location.lng
    ) <= pickArea!.radius;
    MaterialStateColor buttonColor = MaterialStateColor.resolveWith((states) => canBePicked ? Colors.lightGreen : Colors.red);
    return Container(
      margin: const EdgeInsets.all(10),
      child: Column(
        children: <Widget>[
          Text(
            result.formattedAddress!,
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          (canBePicked && (selectText?.isEmpty ?? true))
              || (!canBePicked && (outsideOfPickAreaText?.isEmpty ?? true))
              ? SizedBox.fromSize(
            size: const Size(56, 56), // button width and height
            child: ClipOval(
              child: Material(
                child: InkWell(
                    overlayColor: buttonColor,
                    onTap: () {
                      if(canBePicked) {
                        onPlacePicked!(result);
                      }
                    },
                    child: Icon(canBePicked ? Icons.check_sharp : Icons.app_blocking_sharp, color: buttonColor)
                ),
              ),
            ),
          )
              : SizedBox.fromSize(
            size: Size(MediaQuery.of(context).size.width * 0.8, 56), // button width and height
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: Material(
                child: InkWell(
                    overlayColor: buttonColor,
                    onTap: () {
                      if(canBePicked) {
                        onPlacePicked!(result);
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(canBePicked ? Icons.check_sharp : Icons.app_blocking_sharp, color: buttonColor),
                        SizedBox.fromSize(size: const Size(10, 0)),
                        Text(canBePicked ? selectText! : outsideOfPickAreaText!,
                            style: TextStyle(
                                color: buttonColor
                            )
                        )
                      ],
                    )
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMapIcons(BuildContext context) {
    final RenderBox appBarRenderBox = appBarKey.currentContext!.findRenderObject() as RenderBox;

    return Positioned(
      top: appBarRenderBox.size.height,
      right: 15,
      child: Column(
        children: <Widget>[
          enableMapTypeButton!
              ? SizedBox(
            width: 35,
            height: 35,
            child: RawMaterialButton(
              shape: const CircleBorder(),
              fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.black54 : Colors.white,
              elevation: 8.0,
              onPressed: onToggleMapType,
              child: const Icon(Icons.layers),
            ),
          )
              : Container(),
          const SizedBox(height: 10),
          enableMyLocationButton!
              ? SizedBox(
            width: 35,
            height: 35,
            child: RawMaterialButton(
              shape: const CircleBorder(),
              fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.black54 : Colors.white,
              elevation: 8.0,
              onPressed: onMyLocation,
              child: const Icon(Icons.my_location),
            ),
          )
              : Container(),
        ],
      ),
    );
  }
}