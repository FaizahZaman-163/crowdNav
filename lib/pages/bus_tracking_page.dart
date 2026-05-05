import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/supabase_service.dart';

const _luCenter = LatLng(24.8832, 91.8731);

const _routes = [
  {
    'name': 'Route 1 – Zindabazar',
    'color': Colors.blue,
    'stops': [
      {'name': 'Zindabazar', 'lat': 24.8968, 'lng': 91.8687},
      {'name': 'Ambarkhana', 'lat': 24.8934, 'lng': 91.8724},
      {'name': 'Leading University', 'lat': 24.8832, 'lng': 91.8731},
    ],
  },
  {
    'name': 'Route 2 – Shibganj',
    'color': Colors.green,
    'stops': [
      {'name': 'Shibganj', 'lat': 24.8780, 'lng': 91.8650},
      {'name': 'Modina Market', 'lat': 24.8810, 'lng': 91.8695},
      {'name': 'Leading University', 'lat': 24.8832, 'lng': 91.8731},
    ],
  },
  {
    'name': 'Route 3 – Uposhohor',
    'color': Colors.orange,
    'stops': [
      {'name': 'Uposhohor', 'lat': 24.9010, 'lng': 91.8600},
      {'name': 'Shahjalal Hospital', 'lat': 24.8900, 'lng': 91.8660},
      {'name': 'Leading University', 'lat': 24.8832, 'lng': 91.8731},
    ],
  },
  {
    'name': 'Route 4 – Airport Road',
    'color': Colors.purple,
    'stops': [
      {'name': 'Airport Road', 'lat': 24.9600, 'lng': 91.8700},
      {'name': 'Lalabazar', 'lat': 24.9100, 'lng': 91.8710},
      {'name': 'Leading University', 'lat': 24.8832, 'lng': 91.8731},
    ],
  },
];

class BusTrackingPage extends StatefulWidget {
  const BusTrackingPage({super.key});

  @override
  State<BusTrackingPage> createState() => _BusTrackingPageState();
}

class _BusTrackingPageState extends State<BusTrackingPage> {
  int _selectedRoute = 0;
  List<Map<String, dynamic>> _busLocations = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchBusLocations();

    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _fetchBusLocations(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchBusLocations() async {
    try {
      final data = await SupabaseService.getBusLocations();
      if (!mounted) return;
      setState(() => _busLocations = data);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final route = _routes[_selectedRoute];
    final stops = List<Map<String, dynamic>>.from(route['stops'] as List);
    final routeColor = route['color'] as Color;

    final polylinePoints = stops
        .map((s) => LatLng(
              (s['lat'] as num).toDouble(),
              (s['lng'] as num).toDouble(),
            ))
        .toList();

    return Column(
      children: [
        Container(
          height: 55,
          color: const Color(0xFFECF0F1),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _routes.length,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemBuilder: (context, i) {
              final selected = i == _selectedRoute;

              return GestureDetector(
                onTap: () => setState(() => _selectedRoute = i),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF2ECC71) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2ECC71)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Route ${i + 1}',
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF2ECC71),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          flex: 3,
          child: FlutterMap(
            options: const MapOptions(
              initialCenter: _luCenter,
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.crowdnav.app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: polylinePoints,
                    color: routeColor,
                    strokeWidth: 4,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  ...stops.map(
                    (s) => Marker(
                      point: LatLng(
                        (s['lat'] as num).toDouble(),
                        (s['lng'] as num).toDouble(),
                      ),
                      width: 40,
                      height: 40,
                      child: Column(
                        children: [
                          Icon(Icons.location_on, color: routeColor, size: 28),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            color: Colors.white,
                            child: Text(
                              s['name'].toString(),
                              style: const TextStyle(fontSize: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ..._busLocations.map(
                    (b) => Marker(
                      point: LatLng(
                        (b['latitude'] as num).toDouble(),
                        (b['longitude'] as num).toDouble(),
                      ),
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.directions_bus,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    route['name'].toString(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2ECC71),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: stops.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final stop = stops[i];

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: routeColor,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(stop['name'].toString()),
                        subtitle: const Text(
                          'Morning: 8:00 AM | Noon: 1:00 PM | Eve: 5:00 PM',
                          style: TextStyle(fontSize: 11),
                        ),
                        trailing: const Icon(
                          Icons.access_time,
                          color: Color(0xFF2ECC71),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}