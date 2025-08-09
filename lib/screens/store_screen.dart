import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  Position? _currentPosition;
  bool _loading = true;
  final String _apiKey =
      'AIzaSyC8JtIMqTQ8KByebN3hnijwXPZnt3wzrRs'; // Your API key
  String _searchQuery = ''; // Stores the user's search query

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  /// Gets the current location of the device.
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorDialog('Please enable location services');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        _showErrorDialog('Location permissions are required');
        return;
      }
    }

    try {
      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _loading = false;
      });
      _getNearbyStores(position);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Error getting location: $e');
    }
  }

  /// Fetches nearby stores using Google Places API based on location and search query.
  Future<void> _getNearbyStores(Position position) async {
    const String baseUrl =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json';
    // If the search query is empty, default to "grocery"
    String keyword = _searchQuery.isEmpty ? 'grocery' : _searchQuery;
    // Encode the keyword to ensure a valid URL
    final String encodedKeyword = Uri.encodeComponent(keyword);
    final String url =
        '$baseUrl?location=${position.latitude},${position.longitude}&radius=1500&keyword=$encodedKeyword&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;
        _addStoreMarkers(data['results']);
      } else {
        if (!mounted) return;
        _showErrorDialog(
            'Error fetching stores: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Error fetching stores: $e');
    }
  }

  /// Adds markers for the user's location and the filtered nearby stores.
  void _addStoreMarkers(List<dynamic> stores) {
    // Define a custom icon for stores
    final BitmapDescriptor storeIcon = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueGreen,
    );

    setState(() {
      _markers.clear();
      // Marker for the user's current location
      _markers.add(Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));

      // Create a marker for each nearby store (do not apply extra filtering here;
      // the search query is already used in the API call)
      for (var store in stores) {
        final markerId = store['place_id'];
        _markers.add(Marker(
          markerId: MarkerId(markerId),
          position: LatLng(
            store['geometry']['location']['lat'],
            store['geometry']['location']['lng'],
          ),
          infoWindow: InfoWindow(
            title: store['name'],
            snippet: store['vicinity'],
          ),
          icon: storeIcon,
        ));
      }
    });
  }

  /// Displays an error dialog with the given message.
  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Stores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_currentPosition != null) {
                _getNearbyStores(_currentPosition!);
              }
            },
          )
        ],
      ),
      body: (_loading || _currentPosition == null)
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search stores (e.g. bakery, grocery)",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    if (_currentPosition != null) {
                      _getNearbyStores(_currentPosition!);
                    }
                  },
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onSubmitted: (value) {
                setState(() {
                  _searchQuery = value;
                });
                if (_currentPosition != null) {
                  _getNearbyStores(_currentPosition!);
                }
              },
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                zoom: 14,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (controller) {
                mapController = controller;
              },
            ),
          ),
        ],
      ),
    );
  }
}
