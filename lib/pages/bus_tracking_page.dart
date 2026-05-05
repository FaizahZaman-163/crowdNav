import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/supabase_service.dart';

const _luCenter = LatLng(24.87083280576749, 91.80471333316514);

const _routes = [
  {
    'name': 'Route 1 – Tilagor',
    'color': Colors.blue,
    'schedule': '8:00 | 9:00 | 10:00 | 11:00 | 12:20',
    'return': '11:20 | 12:25 | 1:30 | 3:05 | 4:10',
    'stops': [
      {'name': 'Tilagor', 'lat': 24.89642176189498, 'lng': 91.90042020715494},
      {'name': 'Amberkhana', 'lat': 24.90591570170803, 'lng': 91.87270285382317},
      {'name': 'Jalalabad', 'lat': 24.908983349045297, 'lng': 91.86242393034229},
      {'name': 'Subidbazar', 'lat': 24.90694663702242, 'lng': 91.8577506874772},
      {'name': 'Modina Market', 'lat': 24.91053796605808, 'lng': 91.84804495157724},
      {'name': 'Temukhi Point', 'lat': 24.9128877089896, 'lng': 91.82469036656404},
      {'name': 'Rail Crossing', 'lat': 24.88603205369541, 'lng': 91.83054963650741},
      {'name': 'Leading University', 'lat': 24.86958215653915, 'lng': 91.80484679412363},
    ],
  },
  {
    'name': 'Route 2 - Surma Tower',
    'color': Colors.green,
    'schedule': '8:00 | 9:00 | 10:00 | 11:00 | 12:20',
    'return': '11:20 | 12:25 | 1:30 | 3:05 | 4:10',
    'stops': [
      {'name': 'Surma Tower', 'lat': 24.890431115218927, 'lng': 91.86747836726342},
      {'name': 'Rikabibazar', 'lat': 24.89846994664977, 'lng': 91.8620346187078},
      {'name': 'Subidbazar', 'lat': 24.90694663702242, 'lng': 91.8577506874772},
      {'name': 'SUST Gate', 'lat': 24.911103020929485, 'lng': 91.83221881826707},
      {'name': 'Temukhi Point', 'lat': 24.9128877089896, 'lng': 91.82469036656404},
      {'name': 'Rail Crossing', 'lat': 24.88603205369541, 'lng': 91.83054963650741},
      {'name': 'Kamal Bazar', 'lat': 24.881100914787325, 'lng': 91.80965493504439},
      {'name': 'Leading University', 'lat': 24.86958215653915, 'lng': 91.80484679412363},
    ],
  },
  {
    'name': 'Route 3 - Lakkatura',
    'color': Colors.orange,
    'schedule': '8:00 | 9:00 | 10:00 | 11:00 | 12:20',
    'return': '11:20 | 12:25 | 1:30 | 3:05 | 4:10',
    'stops': [
      {'name': 'Lakkatura', 'lat': 24.924005190701795, 'lng': 91.8713503081673},
      {'name': 'Dorshondewry', 'lat': 24.905860505607578, 'lng': 91.86546685082078},
      {'name': 'Jalalabad', 'lat': 24.908983349045297, 'lng': 91.86242393034229},
      {'name': 'Subidbazar', 'lat': 24.90694663702242, 'lng': 91.8577506874772},
      {'name': 'Modina Market (Hatem Tai)', 'lat': 24.91053796605808, 'lng': 91.84804495157724},
      {'name': 'Temukhi Point', 'lat': 24.9128877089896, 'lng': 91.82469036656404},
      {'name': 'Rail Crossing', 'lat': 24.88603205369541, 'lng': 91.83054963650741},
      {'name': 'Leading University', 'lat': 24.86958215653915, 'lng': 91.80484679412363},
    ],
  },
  {
    'name': 'Route 4 - Tilagor (via Bypass)',
    'color': Colors.purple,
    'schedule': '8:00 | 9:00 | 10:00 | 11:00 | 12:20',
    'return': '11:20 | 12:25 | 1:30 | 3:05 | 4:10',
    'stops': [
      {'name': 'Tilagor', 'lat': 24.89642176189498, 'lng': 91.90042020715494},
      {'name': 'Mirabazar', 'lat': 24.897353487119297, 'lng': 91.88396163369961},
      {'name': 'Naiorpul', 'lat': 24.894819081818806, 'lng': 91.87864313779431},
      {'name': 'Subhanighat', 'lat': 24.890689108627267, 'lng': 91.8782110311111},
      {'name': 'Humayun Rashid Chattar', 'lat': 24.877669453023323, 'lng': 91.87555335331867},
      {'name': 'Chandirpul', 'lat': 24.86782296779714, 'lng': 91.85692396926362},
      {'name': 'Bypass', 'lat': 24.861026347547956, 'lng': 91.84611179436193},
      {'name': 'Rail Crossing', 'lat': 24.88603205369541, 'lng': 91.83054963650741},
      {'name': 'Leading University', 'lat': 24.86958215653915, 'lng': 91.80484679412363},
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