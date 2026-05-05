import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/announcement_model.dart';

class SupabaseService {
  static final _client = Supabase.instance.client;

  static Future<UserModel?> getProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return UserModel.fromMap(data);
  }

  static Future<void> updateProfile(Map<String, dynamic> updates) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('profiles').update(updates).eq('id', userId);
  }

  static Future<void> updateBusLocation({
    required String busId,
    required double lat,
    required double lng,
  }) async {
    await _client.from('bus_locations').upsert({
      'bus_id': busId,
      'latitude': lat,
      'longitude': lng,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getBusLocations() async {
    final data = await _client.from('bus_locations').select();
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Announcement>> getAnnouncements({
    String department = 'all',
    String program = 'all',
  }) async {
    final data = await _client
        .from('announcements')
        .select()
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => Announcement.fromMap(e))
        .where((a) =>
            (a.targetDepartment == 'all' || a.targetDepartment == department) &&
            (a.targetProgram == 'all' || a.targetProgram == program))
        .toList();
  }

  static Future<void> postAnnouncement({
    required String title,
    required String body,
    String targetDepartment = 'all',
    String targetProgram = 'all',
    String priority = 'normal',
  }) async {
    await _client.from('announcements').insert({
      'title': title,
      'body': body,
      'target_department': targetDepartment,
      'target_program': targetProgram,
      'priority': priority,
    });
  }

  static RealtimeChannel busLocationStream(
      void Function(Map<String, dynamic>) onUpdate) {
    return _client
        .channel('bus_locations')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bus_locations',
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
}