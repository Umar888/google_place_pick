import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:turing_demo/google_map/components/app_image.dart';

class FullPhoto extends StatelessWidget {
  final String url;
  final String title;
  const FullPhoto({Key? key, required this.url, required this.title}): super(key:key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        title: Text(title,style: TextStyle(color: Colors.white),),
        centerTitle: true,
      ),
      body: FullPhotoScreen(url: url),
    );

  }
}

class FullPhotoScreen extends StatefulWidget {
  final String url;
  const FullPhotoScreen({Key? key, required this.url}): super(key:key);

  @override
  State createState() => FullPhotoScreenState(url: url);
}

class FullPhotoScreenState extends State<FullPhotoScreen> {
  final String url;
  FullPhotoScreenState({Key? key, required this.url});

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PhotoView(
      loadingBuilder: (context, event) => Container(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        color: Colors.white70,
        child: const Center(
            child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.black))
        ),
      ),
    imageProvider: NetworkImage(url),
    );
  }
}
