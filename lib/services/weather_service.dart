import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final String description;
  final double tempC;
  final double humidity;
  final double windSpeed;
  final String iconCode;
  final bool isRaining;

  const WeatherData({
    required this.description,
    required this.tempC,
    required this.humidity,
    required this.windSpeed,
    required this.iconCode,
    required this.isRaining,
  });

  String get iconUrl => 'https://openweathermap.org/img/wn/$iconCode@2x.png';

  String get commuteTip {
    if (isRaining) return '🌧️ Rain expected – carry an umbrella!';
    if (tempC > 34) return '☀️ Extreme heat – stay hydrated!';
    if (tempC < 18) return '🧥 Cool weather – wear a jacket!';
    if (windSpeed > 10) return '💨 Windy – hold on to your things!';
    return '✅ Weather looks good for commuting!';
  }
}

class WeatherService {
  
  static const _apiKey = '46d0ae609409e76de04e042f17926759 '; 
  static const _city = 'Sylhet,BD';
  static const _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  static Future<WeatherData?> fetchWeather() async {
    try {
      final uri = Uri.parse(
        '$_baseUrl?q=$_city&appid=$_apiKey&units=metric',
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body);
      final weather = json['weather'][0];
      final main = json['main'];
      final wind = json['wind'];

      return WeatherData(
        description: weather['description'],
        tempC: (main['temp'] as num).toDouble(),
        humidity: (main['humidity'] as num).toDouble(),
        windSpeed: (wind['speed'] as num).toDouble(),
        iconCode: weather['icon'],
        isRaining: weather['main'].toString().toLowerCase().contains('rain'),
      );
    } catch (_) {
      return null;
    }
  }
}