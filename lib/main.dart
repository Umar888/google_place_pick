import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'google_map/get_address_from_map.dart';
import 'google_map/providers/place_provider.dart';
import 'google_map/string_constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PlaceProvider>(create: (_) => PlaceProvider(
            mapApiKey,
            "",
            null,
            <String,String>{}
        )),
      ],
      child: MaterialApp(
        title: 'Turing Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.red,
        ),
        home: const GetAddressFromMap(latitude: '',longitude: ""),
      ),
    );
  }
}
