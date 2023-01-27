import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:photo_view/photo_view.dart';
import 'package:turing_demo/google_map/components/app_image.dart';
import 'package:turing_demo/google_map/components/full_image_widget.dart';
import 'package:turing_demo/google_map/models/pick_result.dart';
import 'package:turing_demo/google_map/string_constants.dart';

class AddressDetail extends StatefulWidget {
  PickResult pickResult;

  AddressDetail({super.key,required this.pickResult});

  @override
  _AddressDetailState createState() => _AddressDetailState();
}

class _AddressDetailState extends State<AddressDetail> {


  @override
  void initState() {
    super.initState();
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    super.dispose();
  }




  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text(widget.pickResult.name??"Address Details"),
        automaticallyImplyLeading: true,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 3),
            widget.pickResult.photos != null && widget.pickResult.photos!.isNotEmpty?
            SizedBox(
              height: MediaQuery.of(context).size.height*0.2,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                  itemBuilder:(context,index){
                      return AspectRatio(
                        aspectRatio: 1,
                        child: InkWell(
                          onTap: (){
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (context) =>
                                    FullPhoto(url: "https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=${widget.pickResult.photos![index].photoReference}&key=$mapApiKey",
                                      title: widget.pickResult.photos![index].htmlAttributions.first.split("\">")[1].replaceAll("</a>", ""),
                                    ),
                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              AppImage(
                                fit: BoxFit.cover,
                                height: widget.pickResult.photos![index].height.toDouble(),
                                width: widget.pickResult.photos![index].width.toDouble(),
                                link: "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${widget.pickResult.photos![index].photoReference}&key=$mapApiKey"
                              ),
                              Container(
                                color: Colors.black.withOpacity(0.6),
                               child: Padding(
                                 padding: const EdgeInsets.symmetric(vertical: 2.0,horizontal: 3),
                                 child: Text(widget.pickResult.photos![index].htmlAttributions.first.split("\">")[1].replaceAll("</a>", ""),
                                 style: const TextStyle(
                                   color: Colors.white,
                                   fontSize: 12
                                 ),),
                               )
                              )
                            ],
                          ),
                        ),
                      );
                  },
                  separatorBuilder: (context,index){
                  return Container(width: 2);
                  },
                  itemCount: widget.pickResult.photos!.length),
            ):
            SizedBox(
              height: MediaQuery.of(context).size.height*0.2,
              child: const Center(
                child: Text("No Images found",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold
                    )),
                  ),
                ),
            const SizedBox(height: 10,),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      AppImage(
                        link: widget.pickResult.icon??"",
                        height: 24,
                      ),
                      const SizedBox(width: 5),
                      Text(widget.pickResult.name??"",
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
                        child: Text(widget.pickResult.formattedAddress??"",
                          style: const TextStyle(
                            fontSize:14,
                          ),),
                      ),
                    ],
                  ),
                  widget.pickResult.internationalPhoneNumber != null &&
                      widget.pickResult.internationalPhoneNumber!.isNotEmpty?
                  const SizedBox(height: 10,):const SizedBox.shrink(),
                  widget.pickResult.internationalPhoneNumber != null &&
                      widget.pickResult.internationalPhoneNumber!.isNotEmpty?
                  Row(
                    children: [
                      const Text("Phone:",
                        style: TextStyle(
                            fontSize:14,
                            fontWeight: FontWeight.bold
                        ),),
                      const SizedBox(width: 3),
                      Text(widget.pickResult.internationalPhoneNumber??"",
                        style: const TextStyle(
                          fontSize:14,
                        ),),
                    ],
                  ):const SizedBox.shrink(),
                  widget.pickResult.website != null &&
                      widget.pickResult.website!.isNotEmpty?
                  const SizedBox(height: 10,):const SizedBox.shrink(),
                  widget.pickResult.website != null &&
                      widget.pickResult.website!.isNotEmpty?
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
                        child: Text(widget.pickResult.website??"",
                          style: const TextStyle(
                            fontSize:14,
                          ),),
                      ),
                    ],
                  ):const SizedBox.shrink(),
                  widget.pickResult.openingHours != null?
                  const SizedBox(height: 20,):const SizedBox.shrink(),
                  widget.pickResult.openingHours != null?
                      const Divider(height: 1,color: Colors.black87,):const SizedBox.shrink(),
                  widget.pickResult.openingHours != null?
                  const SizedBox(height: 20,):const SizedBox.shrink(),
                  widget.pickResult.openingHours != null?
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text("Opening Hours:",
                            style: TextStyle(
                                fontSize:14,
                                fontWeight: FontWeight.bold
                            ),),
                          const SizedBox(width: 3),
                          Text(widget.pickResult.openingHours!.openNow?"Opened":"Closed Now",
                            style:  TextStyle(
                              fontSize:14,
                              color: widget.pickResult.openingHours!.openNow?Colors.green.shade600:Colors.red
                            ),),

                        ],
                      ),
                      const SizedBox(height: 3,),
                      ListView.builder(
                        shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          primary: false,
                          itemCount: widget.pickResult.openingHours!.weekdayText.length,
                          itemBuilder: (context,index){
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3.0),
                            child: Text(widget.pickResult.openingHours!.weekdayText[index]),
                          );
                          })
                    ],
                  ):const SizedBox.shrink(),
                  widget.pickResult.reviews != null?
                  const Divider(height: 1,color: Colors.black87,):const SizedBox.shrink(),
                  widget.pickResult.reviews != null?
                  const SizedBox(height: 15,):const SizedBox.shrink(),
                  widget.pickResult.reviews != null?
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text("Reviews:",
                        style: TextStyle(
                            fontSize:16,
                            fontWeight: FontWeight.bold
                        ),),
                      const SizedBox(height: 10),
                      ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          primary: false,
                          itemCount: widget.pickResult.reviews!.length,
                          itemBuilder: (context,index){
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppImage(
                                  shape: BoxShape.circle,
                                  link: widget.pickResult.reviews![index].profilePhotoUrl,
                                  height: 40,
                                  width: 40,
                                ),
                                const SizedBox(width: 5,),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(widget.pickResult.reviews![index].authorName,
                                        style: const TextStyle(
                                        fontWeight: FontWeight.bold
                                      ),),
                                      SizedBox(height: 5,),
                                      Row(
                                        children: [
                                          RatingBarIndicator(
                                            itemBuilder: (context, _) => Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 16,
                                            ),
                                            itemSize: 16,
                                            direction: Axis.horizontal,
                                            rating: widget.pickResult.reviews![index].rating.toDouble(),
                                            itemCount: 5,
                                          ),
                                          SizedBox(width: 5,),
                                          Text(widget.pickResult.reviews![index].relativeTimeDescription,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.normal
                                            ),),
                                        ],
                                      ),
                                      SizedBox(height: 5,),
                                      Text(widget.pickResult.reviews![index].text,
                                        style: const TextStyle(
                                        fontWeight: FontWeight.normal
                                      ),),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        separatorBuilder: (BuildContext context, int index) {
                            return const Divider();
                        },)

                    ],
                  ):const SizedBox.shrink(),


                ],
              ),
            )

          ],
        ),
      ),
    );
  }
}

void hideKeyBoard(BuildContext context) {
  FocusScopeNode currentFocus = FocusScope.of(context);
  if (!currentFocus.hasPrimaryFocus) {
    currentFocus.unfocus();
  }
}
