import 'dart:async';
import 'dart:developer';


import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:turing_demo/google_map/string_constants.dart';
import '../utils/shared_preference/shared_preference.dart';
import 'assets.dart';
import 'components/floating_card.dart';
import 'models/pick_result.dart';
import 'place_picker.dart';



class GetAddressFromMap extends StatefulWidget {

  final String latitude;
  final String longitude;
  const GetAddressFromMap({Key? key, required this.latitude,  required this.longitude}) : super(key: key);


  @override
  _MapState createState() => _MapState();
}

class _MapState extends State<GetAddressFromMap> {
  late GoogleMapController _googleMapController;
  late PickResult selectedPlace;
  LatLng _initialPosition=LatLng(double.parse("0"),double.parse("0"));
  String currentAddress="";
  SharedPreference sharedPreference = SharedPreference();
  bool showMap=false;
  @override
  void initState() {
    sharedPreference.readString(myLatitude).then((myLatitude){
      if (kDebugMode) {
        print("myLatitude $myLatitude");
      }
      sharedPreference.readString(myLongitude).then((myLongitude){
        if (kDebugMode) {
          print("myLongitude $myLongitude");
        }
        if(myLatitude.isNotEmpty && myLongitude.isNotEmpty){
          setState(() {
            _initialPosition=LatLng(double.parse(myLatitude),double.parse(myLongitude));
          });
        }
        else{
          setState(() {
            _initialPosition=LatLng(double.parse(defaultLat),double.parse(defaultLon));
          });
        }
      });
    });
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _initialPosition.latitude==0?const CupertinoActivityIndicator():
        PlacePicker(
          mapStyle: Assets.mapLight,
          apiKey: mapApiKey,
          initialPosition: _initialPosition,
          useCurrentLocation: true,
          desiredLocationAccuracy: LocationAccuracy.high,
          enableMapTypeButton: true,
          enableMyLocationButton: true,
          initialMapType: MapType.normal,
          resizeToAvoidBottomInset: true,

          automaticallyImplyAppBarLeading :false,
          selectInitialPosition: true,
          usePlaceDetailSearch: true,
          onMapCreated: (controller){},
          onTapBack: (){
            Navigator.pop(context);
          },
          onPlacePicked: (result) {
            selectedPlace = result;
            debugPrint("selectedPlace $selectedPlace");
            setState(() {});
          },
          selectedPlaceWidgetBuilder: (_, selectedPlace, state, isSearchBarFocused) {
            debugPrint("state: $state, isSearchBarFocused: $isSearchBarFocused");
            return isSearchBarFocused
                ? Container(
              margin: const EdgeInsets.only(top:20),
            ):
            FloatingCard(
                bottomPosition: 20.0, // MediaQuery.of(context) will cause rebuild. See MediaQuery document for the information.
                leftPosition: 20.0,
                rightPosition: 20.0,
                elevation: 10.0,
                borderRadius: BorderRadius.circular(10.0),
                child:Container(
                  padding: const EdgeInsets.all(10.0),
                  child: state == SearchingState.Searching?
                  Center(
                        child: Column(
                          children:  const [
                            SizedBox(height: 10,),
                            CircularProgressIndicator(),
                            SizedBox(height: 10,)
                          ]
                        )):
                  Center(
                       child: Column(

                      children: [
                        Text(selectedPlace!.formattedAddress??"",
                          textAlign: TextAlign.center,
                          style:  const TextStyle(

                            fontWeight: FontWeight.w300,
                          ),),
                      ],
                    ),
                    ),
                ));
          },
        ),
      ),

    );
  }

}