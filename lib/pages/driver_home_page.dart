import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import '../auth/login_page.dart';
import '../pages/profile_page.dart';

const _routes = [
  {'id': 'route_1', 'name': 'Route 1 – Tilagor', 'stops': ['Tilagor', 'Amberkhana', 'Jalalabad', 'Subidbazar', 'Modina Market', 'Temukhi Point', 'Rail Crossing', 'Leading University']},
  {'id': 'route_2', 'name': 'Route 2 – Surma Tower', 'stops': ['Surma Tower', 'Rikabibazar', 'Subidbazar', 'SUST Gate', 'Temukhi Point', 'Rail Crossing', 'Kamal Bazar', 'Leading University']},
  {'id': 'route_3', 'name': 'Route 3 – Lakkatura', 'stops': ['Lakkatura', 'Dorshondewry', 'Jalalabad', 'Subidbazar', 'Modina Market', 'Temukhi Point', 'Rail Crossing', 'Leading University']},
  {'id': 'route_4', 'name': 'Route 4 – Tilagor (Bypass)', 'stops': ['Tilagor', 'Mirabazar', 'Naiorpul', 'Subhanighat', 'Humayun Rashid Chattar', 'Chandirpul', 'Bypass', 'Rail Crossing', 'Leading University']},
];

class DriverHomePage extends StatefulWidget {
  final UserModel user;
  const DriverHomePage({super.key, required this.user});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  int _currentIndex = 0;
  bool _isBroadcasting = false;
  int _selectedRouteIndex = 0;
  StreamSubscription<Position>? _positionSub;
  DateTime? _lastUpdate;
  String _statusMessage = 'Tap Start to begin sharing your location.';
  int _broadcastSeconds = 0;
  Timer? _durationTimer;

  @override
  void dispose() {
    _stopBroadcast();
    _durationTimer?.cancel();
    super.dispose();
  }

  Future<void> _startBroadcast() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('Location services are disabled. Please enable GPS.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError('Location permission denied.');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showError('Location permission permanently denied. Enable in settings.');
      return;
    }

    setState(() {
      _isBroadcasting = true;
      _broadcastSeconds = 0;
      _statusMessage = 'Broadcasting location...';
    });

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _broadcastSeconds++);
    });

    final assignedName = widget.user.assignedRoute;
    final routeIndex = assignedName != null
        ? _routes.indexWhere((r) => r['name'] == assignedName)
        : _selectedRouteIndex;
    final routeId = _routes[routeIndex >= 0 ? routeIndex : 0]['id'] as String;

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (position) async {
        setState(() {
          _lastUpdate = DateTime.now();
          _statusMessage =
              'Broadcasting — ${position.latitude.toStringAsFixed(5)}, '
              '${position.longitude.toStringAsFixed(5)}';
        });
        try {
          await SupabaseService.updateBusLocation(
            busId: routeId,
            lat: position.latitude,
            lng: position.longitude,
          );
        } catch (_) {}
      },
      onError: (_) {
        _showError('Lost GPS signal. Please try again.');
        _stopBroadcast();
      },
    );
  }

  void _stopBroadcast() {
    _positionSub?.cancel();
    _positionSub = null;
    _durationTimer?.cancel();
    if (mounted) {
      setState(() {
        _isBroadcasting = false;
        _statusMessage = 'Broadcasting stopped.';
      });
    }
    try {
      final assignedName = widget.user.assignedRoute;
    final routeIndex = assignedName != null
        ? _routes.indexWhere((r) => r['name'] == assignedName)
        : _selectedRouteIndex;
    final routeId = _routes[routeIndex >= 0 ? routeIndex : 0]['id'] as String;
      SupabaseService.clearBusLocation(busId: routeId);
    } catch (_) {}
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _signOut() async {
    _stopBroadcast();
    await SupabaseService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  int get _effectiveRouteIndex {
    final assignedName = widget.user.assignedRoute;
    if (assignedName == null) return _selectedRouteIndex;
    final idx = _routes.indexWhere((r) => r['name'] == assignedName);
    return idx >= 0 ? idx : _selectedRouteIndex;
  }

  Widget _buildRouteCard() {
    final assigned = widget.user.assignedRoute;
    if (assigned != null) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assigned Route', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF2ECC71))),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2ECC71)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_bus, color: Color(0xFF2ECC71)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        assigned,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E8449)),
                      ),
                    ),
                    const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Route assigned by admin. Contact admin to change.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Your Route', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF2ECC71))),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No route assigned yet. Ask your admin to assign a route, or select manually below.',
                      style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue: _selectedRouteIndex,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF9F9F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: _routes.asMap().entries.map((e) => DropdownMenuItem(
                value: e.key,
                child: Text(e.value['name'] as String),
              )).toList(),
              onChanged: _isBroadcasting ? null : (v) => setState(() => _selectedRouteIndex = v!),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final route = _routes[_effectiveRouteIndex];
    final stops = List<String>.from(route['stops'] as List);

    return Scaffold(
      backgroundColor: const Color(0xFFECF0F1),
      appBar: AppBar(
        title: Text('CrowdNav – Driver', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: const Color(0xFF1E8449),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _signOut,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: const Color(0xFF2ECC71),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.directions_bus), label: 'My Route'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      body: _currentIndex == 1
          ? ProfilePage(user: widget.user)
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Driver info ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Color(0xFF2ECC71), size: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.name.isNotEmpty ? widget.user.name : 'Driver',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.user.phone.isNotEmpty ? widget.user.phone : 'No phone',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isBroadcasting ? Colors.white : Colors.white30,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isBroadcasting ? 'ONLINE' : 'OFFLINE',
                    style: TextStyle(
                      color: _isBroadcasting ? const Color(0xFF2ECC71) : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Assigned route display ───────────────────────────
          _buildRouteCard(),

          const SizedBox(height: 16),

          // ── Broadcast control ────────────────────────────────
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    _isBroadcasting ? Icons.location_on : Icons.location_off,
                    size: 56,
                    color: _isBroadcasting ? const Color(0xFF2ECC71) : Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  if (_isBroadcasting)
                    Text(
                      _formatDuration(_broadcastSeconds),
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2ECC71),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: _isBroadcasting ? const Color(0xFF1E8449) : Colors.grey,
                    ),
                  ),
                  if (_lastUpdate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Last update: ${_lastUpdate!.hour.toString().padLeft(2, '0')}:${_lastUpdate!.minute.toString().padLeft(2, '0')}:${_lastUpdate!.second.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isBroadcasting ? _stopBroadcast : _startBroadcast,
                      icon: Icon(_isBroadcasting ? Icons.stop : Icons.play_arrow),
                      label: Text(
                        _isBroadcasting ? 'Stop Broadcasting' : 'Start Broadcasting',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isBroadcasting ? Colors.redAccent : const Color(0xFF2ECC71),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Route stops ──────────────────────────────────────
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Route Stops', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF2ECC71))),
                  const SizedBox(height: 10),
                  ...stops.asMap().entries.map((e) {
                    final isFirst = e.key == 0;
                    final isLast = e.key == stops.length - 1;
                    return Row(
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: isFirst || isLast ? const Color(0xFF2ECC71) : Colors.grey.shade300,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF2ECC71), width: 2),
                              ),
                            ),
                            if (!isLast)
                              Container(width: 2, height: 28, color: Colors.grey.shade300),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            e.value,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isFirst || isLast ? FontWeight.bold : FontWeight.normal,
                              color: isFirst || isLast ? const Color(0xFF1E8449) : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}