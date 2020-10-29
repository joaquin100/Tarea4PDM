import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeMap extends StatefulWidget {
  HomeMap({Key key}) : super(key: key);

  @override
  _HomeMapState createState() => _HomeMapState();
}

class _HomeMapState extends State<HomeMap> {
  final Set<Marker> _mapMarkers = Set();
  Set<Polygon> _polygons = Set();
  GoogleMapController _mapController;
  String searchAddr;
  Position _currentPosition;
  final Position _defaultPosition = Position(
    longitude: 20.608148,
    latitude: -103.417576,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getCurrentPosition(),
      builder: (context, result) {
        if (result.error == null) {
          _currentPosition ??= _defaultPosition;
          return Scaffold(
            appBar: AppBar(
              title: Text('Google Maps y Geolocator'),
              centerTitle: true,
            ),
            drawer: _drawer(context),
            body: Stack(
              children: <Widget>[
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  markers: _mapMarkers,
                  onLongPress: _setMarker,
                  polygons: _polygons,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition.latitude,
                      _currentPosition.longitude,
                    ),
                  ),
                ),
                Positioned(
                  top: 30.0,
                  right: 15.0,
                  left: 15.0,
                  child: Container(
                    height: 50.0,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: Colors.white,
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Enter Address',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.only(
                          left: 15.0,
                          top: 15.0,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.search),
                          onPressed: _searchandNavigate,
                          iconSize: 30.0,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          searchAddr = val;
                        });
                      },
                      onSubmitted: (term) {
                        _searchandNavigate();
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          Scaffold(
            body: Center(child: Text('Error!')),
          );
        }
        return Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  void _searchandNavigate() {
    Geolocator().placemarkFromAddress(searchAddr).then(
      (result) {
        _mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                result[0].position.latitude,
                result[0].position.longitude,
              ),
              zoom: 10.0,
            ),
          ),
        );
        //
      },
    );
  }

  void _onMapCreated(controller) {
    setState(() {
      _mapController = controller;
    });
  }

  void _setMarker(LatLng coord) async {
    // get address
    // ignore: omit_local_variable_types
    String _markerAddress = await _getGeolocationAddress(
      Position(latitude: coord.latitude, longitude: coord.longitude),
    );

    // add marker
    setState(() {
      _mapMarkers.add(
        Marker(
          markerId: MarkerId(coord.toString()),
          position: coord,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          onTap: () {
            showModalBottomSheet(
                context: context,
                builder: (BuildContext bc) {
                  return Container(
                    child: ListView(
                      children: <Widget>[
                        ListTile(
                          title: Text('Address: '),
                          subtitle: Text(_markerAddress),
                        ),
                        ListTile(
                          title: Text('Latitude and longitude: '),
                          subtitle: Text(
                              'lat:${coord.latitude}, lng:${coord.longitude}'),
                        ),
                      ],
                    ),
                  );
                });
          },
        ),
      );
    });
  }

  Future<void> _getCurrentPosition() async {
    // get current position
    _currentPosition = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    // get address
    String _currentAddress = await _getGeolocationAddress(_currentPosition);

    // add marker
    _mapMarkers.add(
      Marker(
        markerId: MarkerId(_currentPosition.toString()),
        position: LatLng(
          _currentPosition.latitude,
          _currentPosition.longitude,
        ),
        infoWindow: InfoWindow(
          title: _currentPosition.toString(),
          snippet: _currentAddress,
        ),
      ),
    );

    // move camera
    await _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            _currentPosition.latitude,
            _currentPosition.longitude,
          ),
          zoom: 15.0,
        ),
      ),
    );
  }

  Future<String> _getGeolocationAddress(Position position) async {
    var places = await Geolocator().placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (places != null && places.isNotEmpty) {
      Placemark place = places.first;
      return '${place.thoroughfare}, ${place.locality}';
    }
    return 'No address availabe';
  }

  void _drawPolygons() {
    setState(() {
      if (_polygons.isEmpty) {
        // ignore: prefer_collection_literals
        List<LatLng> coordinates_list = List();
        _mapMarkers.forEach((marker) {
          if (marker.position.latitude != _currentPosition.latitude ||
              marker.position.longitude != marker.position.longitude) {
            coordinates_list.add(marker.position);
          }
        });
        _polygons.add(Polygon(
          polygonId: PolygonId('polygon'),
          points: coordinates_list,
          strokeColor: Colors.grey,
          fillColor: Colors.blue,
        ));
      }
    });
  }

  void _deletePolygon() {
    setState(() {
      _polygons = Set();
    });
  }

  Widget _drawer(context) {
    return Drawer(
      child: Container(
        child: ListView(
          children: <Widget>[
            Divider(),
            ListTile(
              onTap: () {
                _getCurrentPosition();
                Navigator.of(context).pop();
              },
              title: Text(
                'Current Position',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
              trailing: Icon(Icons.location_history_outlined),
            ),
            Divider(),
            ListTile(
              onTap: () {
                print('Creating polygon');
                _drawPolygons();
                Navigator.of(context).pop();
              },
              title: Text(
                'Draw a Polygon',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
            Divider(),
            ListTile(
              onTap: () {
                print('Deleting polygon');
                _deletePolygon();
                Navigator.of(context).pop();
              },
              title: Text(
                'Delete the Polygon',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
