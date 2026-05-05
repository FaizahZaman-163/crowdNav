import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const _nodes = {
  'Gate': LatLng(24.8820, 91.8715),
  'Main Building': LatLng(24.8832, 91.8731),
  'CSE Dept': LatLng(24.8838, 91.8740),
  'Library': LatLng(24.8825, 91.8750),
  'Cafeteria': LatLng(24.8815, 91.8745),
  'Auditorium': LatLng(24.8842, 91.8722),
  'Admin Block': LatLng(24.8829, 91.8718),
  'Bus Stop': LatLng(24.8810, 91.8710),
};

final _edges = <String, Map<String, double>>{
  'Gate': {'Main Building': 2.0, 'Bus Stop': 1.0, 'Admin Block': 1.5},
  'Main Building': {
    'Gate': 2.0,
    'CSE Dept': 1.2,
    'Library': 1.8,
    'Cafeteria': 1.5,
    'Admin Block': 1.0,
    'Auditorium': 1.3,
  },
  'CSE Dept': {'Main Building': 1.2, 'Library': 0.8, 'Auditorium': 1.0},
  'Library': {'CSE Dept': 0.8, 'Main Building': 1.8, 'Cafeteria': 0.9},
  'Cafeteria': {'Library': 0.9, 'Main Building': 1.5, 'Bus Stop': 1.2},
  'Auditorium': {'Main Building': 1.3, 'CSE Dept': 1.0, 'Admin Block': 0.7},
  'Admin Block': {'Gate': 1.5, 'Main Building': 1.0, 'Auditorium': 0.7},
  'Bus Stop': {'Gate': 1.0, 'Cafeteria': 1.2},
};

class _Node {
  final String name;
  final double cost;
  const _Node(this.name, this.cost);
}

List<String> _dijkstra(String start, String end) {
  final dist = <String, double>{};
  final prev = <String, String?>{};
  final pq = HeapPriorityQueue<_Node>((a, b) => a.cost.compareTo(b.cost));

  for (final n in _nodes.keys) {
    dist[n] = double.infinity;
    prev[n] = null;
  }

  dist[start] = 0;
  pq.add(_Node(start, 0));

  while (pq.isNotEmpty) {
    final current = pq.removeFirst();

    if (current.name == end) break;
    if (current.cost > dist[current.name]!) continue;

    for (final neighbor in (_edges[current.name] ?? {}).entries) {
      final newCost = dist[current.name]! + neighbor.value;

      if (newCost < dist[neighbor.key]!) {
        dist[neighbor.key] = newCost;
        prev[neighbor.key] = current.name;
        pq.add(_Node(neighbor.key, newCost));
      }
    }
  }

  final path = <String>[];
  String? current = end;

  while (current != null) {
    path.insert(0, current);
    current = prev[current];
  }

  return (path.isNotEmpty && path.first == start) ? path : [];
}

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  String _from = 'Gate';
  String _to = 'CSE Dept';
  List<String> _path = [];

  void _calculateRoute() {
    setState(() {
      _path = _dijkstra(_from, _to);
    });
  }

  List<LatLng> get _polylinePoints =>
      _path.map((n) => _nodes[n]!).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // TOP BAR (clean modern UI)
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFFECF0F1),
          child: Row(
            children: [
              Expanded(
                child: _DropdownNode(
                  label: 'From',
                  value: _from,
                  onChanged: (v) => setState(() => _from = v!),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, color: Color(0xFF2ECC71)),
              const SizedBox(width: 8),
              Expanded(
                child: _DropdownNode(
                  label: 'To',
                  value: _to,
                  onChanged: (v) => setState(() => _to = v!),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _calculateRoute,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Go'),
              ),
            ],
          ),
        ),

        // MAP
        Expanded(
          flex: 3,
          child: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(24.8830, 91.8730),
              initialZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.crowdnav.app',
              ),

              if (_polylinePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _polylinePoints,
                      color: const Color(0xFF2ECC71),
                      strokeWidth: 5,
                    ),
                  ],
                ),

              MarkerLayer(
                markers: _nodes.entries.map((e) {
                  final isOnPath = _path.contains(e.key);

                  return Marker(
                    point: e.value,
                    width: 60,
                    height: 50,
                    child: Column(
                      children: [
                        Icon(
                          e.key == _from
                              ? Icons.trip_origin
                              : e.key == _to
                                  ? Icons.location_on
                                  : Icons.circle,
                          color: isOnPath
                              ? const Color(0xFF2ECC71)
                              : Colors.grey,
                          size: isOnPath ? 24 : 16,
                        ),
                        Text(
                          e.key,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: isOnPath
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isOnPath
                                ? const Color(0xFF2ECC71)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // PATH DISPLAY
        if (_path.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shortest Path (Dijkstra)',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2ECC71),
                  ),
                ),
                const SizedBox(height: 8),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _path.map((node) {
                      final isLast = node == _path.last;

                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2ECC71),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              node,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (!isLast)
                            const Icon(Icons.arrow_forward,
                                size: 16, color: Colors.grey),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// CLEAN DROPDOWN (FIXED + SAFE)
class _DropdownNode extends StatelessWidget {
  final String label;
  final String value;
  final void Function(String?) onChanged;

  const _DropdownNode({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _nodes.containsKey(value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      items: _nodes.keys
          .map((n) => DropdownMenuItem(
                value: n,
                child: Text(n, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}