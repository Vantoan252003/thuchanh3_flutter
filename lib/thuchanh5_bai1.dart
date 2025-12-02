import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Tin tức Thời tiết",
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final TextEditingController _cityController = TextEditingController();
  Map<String, dynamic>? _weatherData;
  bool _isLoading = false;
  String? _errorMessage;

  static const String apiKey = "7a76f851c92c43de109835a0a53b4fe7"; //Thay bằng API key của bạn
  static const String apiUrl = "https://api.openweathermap.org/data/2.5/weather";

  @override
  void initState() {
    super.initState();
    _loadLastCity();
  }

  Future<void> _loadLastCity() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCity = prefs.getString('last_city');
    if (lastCity != null && lastCity.isNotEmpty) {
      _cityController.text = lastCity;
      _fetchWeather(lastCity);
    }
  }

  Future<void> _saveLastCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_city', city);
  }

  Future<void> _fetchWeather(String city) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse('$apiUrl?q=$city&appid=$apiKey&units=metric&lang=vi');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _weatherData = data;
        });
        _saveLastCity(city);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Không thể lấy dữ liệu thời tiết.');
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Không thể lấy dữ liệu thời tiết. Vui lòng thử lại.";
        _weatherData = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildWeatherInfo() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_weatherData == null) {
      return const Center(child: Text("Nhập tên thành phố để xem thời tiết"));
    }

    final main = _weatherData!['main'];
    final weather = _weatherData!['weather'][0];
    final temp = main['temp'];
    final humidity = main['humidity'];
    final description = weather['description'];
    final icon = weather['icon'];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.network(
          'https://openweathermap.org/img/wn/$icon@2x.png',
          width: 100,
          height: 100,
        ),
        Text(
          "${temp.toStringAsFixed(1)}°C",
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
        Text(
          description.toString().toUpperCase(),
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 10),
        Text("Độ ẩm: $humidity%"),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🌤️ Tin tức Thời tiết"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: "Nhập tên thành phố",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _cityController.clear(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                final city = _cityController.text.trim();
                if (city.isNotEmpty) {
                  _fetchWeather(city);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Vui lòng nhập tên thành phố")),
                  );
                }
              },
              icon: const Icon(Icons.search),
              label: const Text("Xem thời tiết"),
            ),
            const SizedBox(height: 30),
            Expanded(child: _buildWeatherInfo()),
          ],
        ),
      ),
    );
  }
}
