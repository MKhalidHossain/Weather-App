import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:video_player/video_player.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    _getCurrentLocation();
    return await Geolocator.getCurrentPosition();
  }

  var lat;
  var long;

  _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    lat = position.latitude;
    long = position.longitude;
    print(" Your Location is ${lat},${long}");
    _getDataFromApi();
  }

  Map<String, dynamic>? weatherMap;
  Map<String, dynamic>? forecastMap;

  _getDataFromApi() async {
    var weatherResponse = await http.post(Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${long}&appid=4b142be1f90d130cf2f06586f711464a&units=metric"));
    var forecastResponse = await http.post(Uri.parse(
        "https://api.openweathermap.org/data/2.5/forecast?lat=${lat}&lon=${long}&appid=4b142be1f90d130cf2f06586f711464a&units=metric"));

    var weather = jsonDecode(weatherResponse.body);
    var forecast = jsonDecode(forecastResponse.body);

    setState(() {
      weatherMap = Map<String, dynamic>.from(weather);
      forecastMap = Map<String, dynamic>.from(forecast);
    });
  }

  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    // Pointing the video controller to our local asset.
    _controller = VideoPlayerController.asset("assets/videos/background.mp4")
      ..initialize().then((_) {
        // Once the video has been loaded we play the video and set looping to true.
        _controller?.play();
        _controller!.setLooping(true);
        // Ensure the first frame is shown after the video is initialized.
        setState(() {});
      });
  }

  TextEditingController _searchController = TextEditingController();

  _searchDataFromApi() async {
    var weatherResponse = await http.post(Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?q=${_searchController.text}&appid=4b142be1f90d130cf2f06586f711464a&units=metric"));
    var forecastResponse = await http.post(Uri.parse(
        "https://api.openweathermap.org/data/2.5/forecast?q=${_searchController.text}&appid=4b142be1f90d130cf2f06586f711464a&units=metric"));

    var weather = jsonDecode(weatherResponse.body);
    var forecast = jsonDecode(forecastResponse.body);

    setState(() {
      weatherMap = Map<String, dynamic>.from(weather);
      forecastMap = Map<String, dynamic>.from(forecast);
    });
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  insetPadding: EdgeInsets.all(0),
                  backgroundColor: Colors.white.withOpacity(0.95),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 10,
                      ),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40),
                        )),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40.0)),
                              primary: Color.fromARGB(255, 210, 172, 162)),
                          onPressed: () {
                            if (_searchController.text != "") {
                              _searchDataFromApi();
                              Navigator.of(context).pop();
                            }
                          },
                          child: Text(
                            'Search',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      )
                    ],
                  ),
                );
              });
        },
        backgroundColor: Color.fromARGB(255, 210, 172, 162),
        child: Icon(Icons.search),
      ),
      body: weatherMap == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Stack(
              children: [
                SizedBox.expand(
                  child: FittedBox(
                    // If your background video doesn't look right, try changing the BoxFit property.
                    // BoxFit.fill created the look I was going for.
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(20),
                  color: Colors.black.withOpacity(0.3),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                Text(
                                  "${weatherMap!["name"]}",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 25),
                                )
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  " ${Jiffy("${DateTime.now()}").format('MMM do yyyy')}",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 20),
                                ),
                                Text(
                                  "${Jiffy("${DateTime.now()}").format('EEE hh mm a')}",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 20),
                                )
                              ],
                            )
                          ],
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${weatherMap!["main"]["temp"].toString().split(".")[0]}",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 200),
                            ),
                            Text(
                              "°C",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 80),
                            ),
                          ],
                        ),
                        Container(
                          height: 80,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.black.withOpacity(0.2)),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  "Humidity: ${weatherMap!["main"]["humidity"]} | Presure : ${weatherMap!["main"]["pressure"]}",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 18),
                                ),
                                Text(
                                  "Sunrise: ${Jiffy(DateTime.fromMillisecondsSinceEpoch(weatherMap!["sys"]["sunrise"] * 1000)).format('hh mm a')} | Sunset : ${Jiffy(DateTime.fromMillisecondsSinceEpoch(weatherMap!["sys"]["sunset"] * 1000)).format('hh mm a')}",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 18),
                                )
                              ]),
                        )
                      ],
                    ),
                  ),
                ),
                Positioned(
                    bottom: 0,
                    child: Container(
                      height: 300,
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(40),
                              topRight: Radius.circular(40))),
                      child: Column(children: [
                        Container(
                          padding: EdgeInsets.all(15),
                          child: Text(
                            "Weather Forecast",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Container(
                          height: 200,
                          child: ListView.separated(
                              padding: EdgeInsets.only(
                                left: 20,
                                right: 20,
                              ),
                              physics: BouncingScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              itemBuilder: ((context, index) => Container(
                                    width: 150,
                                    decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.2),
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Image.network(
                                            "https://openweathermap.org/img/wn/${forecastMap!["list"][index + 2]["weather"][0]["icon"]}@2x.png"),
                                        Text(
                                          "${Jiffy("${forecastMap!["list"][index + 2]["dt_txt"]}").format("EEE h mm a")}",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${forecastMap!["list"][index + 2]["main"]["temp"].toString().split(".")[0]}",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 50),
                                            ),
                                            Text(
                                              "°C",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )),
                              separatorBuilder: ((context, index) => SizedBox(
                                    width: 10,
                                  )),
                              itemCount: forecastMap!["list"].length - 3),
                        )
                      ]),
                    )),
              ],
            ),
    );
  }
}
