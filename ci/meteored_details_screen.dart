import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shamsi_date/shamsi_date.dart';

class MeteoredDetailsScreen extends StatefulWidget {
  const MeteoredDetailsScreen({super.key});
  @override
  State<MeteoredDetailsScreen> createState() => _MeteoredDetailsScreenState();
}

class _MeteoredDetailsScreenState extends State<MeteoredDetailsScreen> {
  static const blue = Color(0xff087fc7);
  double lat = 35.6892, lon = 51.3890;
  String city = 'تهران';
  Map<String, dynamic>? weather, air;
  String? radar, error;
  bool busy = true, layer = true;
  int tab = 0;

  @override
  void initState() { super.initState(); _restore(); }

  Future<void> _restore() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      city = p.getString('meteored_city') ?? 'تهران';
      lat = p.getDouble('meteored_lat') ?? lat;
      lon = p.getDouble('meteored_lon') ?? lon;
      final cached = p.getString('meteored_weather');
      if (cached != null) {
        try { weather = jsonDecode(cached) as Map<String, dynamic>; } catch (_) {}
      }
    });
    await _load();
  }

  Future<Map<String, dynamic>> _get(Uri url) async {
    final r = await http.get(url).timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) throw Exception('سرویس در دسترس نیست');
    final data = jsonDecode(utf8.decode(r.bodyBytes));
    if (data is! Map<String, dynamic> || data['error'] == true) {
      throw Exception('داده نامعتبر است');
    }
    return data;
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { busy = true; error = null; });
    try {
      final w = await _get(Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': lat.toString(), 'longitude': lon.toString(),
        'timezone': 'auto', 'forecast_days': '14',
        'current': 'temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m',
        'hourly': 'temperature_2m,precipitation_probability,weather_code',
        'daily': 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max,uv_index_max,sunrise,sunset',
      }));
      final p = await SharedPreferences.getInstance();
      await p.setString('meteored_weather', jsonEncode(w));
      await p.setString('meteored_city', city);
      await p.setDouble('meteored_lat', lat);
      await p.setDouble('meteored_lon', lon);
      if (mounted) setState(() => weather = w);
      try {
        final a = await _get(Uri.https('air-quality-api.open-meteo.com', '/v1/air-quality', {
          'latitude': lat.toString(), 'longitude': lon.toString(),
          'timezone': 'auto', 'current': 'us_aqi,pm2_5,pm10',
        }));
        if (mounted) setState(() => air = a);
      } catch (_) {}
      try {
        final r = await _get(Uri.https('api.rainviewer.com', '/public/weather-maps.json'));
        final past = (r['radar'] as Map<String, dynamic>?)?['past'] as List<dynamic>?;
        if (past != null && past.isNotEmpty) {
          final f = past.last as Map<String, dynamic>;
          if (mounted) setState(() => radar =
              r['host'].toString() + f['path'].toString() + '/256/{z}/{x}/{y}/2/1_1.png');
        }
      } catch (_) {}
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _gps() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw Exception('GPS خاموش است');
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
        throw Exception('مجوز مکان داده نشده است');
      }
      final v = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() { lat = v.latitude; lon = v.longitude; city = 'موقعیت فعلی'; });
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _search() async {
    final input = TextEditingController();
    List<dynamic> results = [];
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context, isScrollControlled: true, useSafeArea: true,
      builder: (ctx) => StatefulBuilder(builder: (context, update) => Padding(
        padding: EdgeInsets.fromLTRB(16, 18, 16, MediaQuery.of(context).viewInsets.bottom + 18),
        child: SizedBox(height: 380, child: Column(children: [
          TextField(controller: input, textInputAction: TextInputAction.search,
            decoration: const InputDecoration(labelText: 'نام شهر', prefixIcon: Icon(Icons.search)),
            onSubmitted: (q) async {
              try {
                final r = await _get(Uri.https('geocoding-api.open-meteo.com','/v1/search',
                  {'name': q, 'count': '10', 'language': 'fa', 'format': 'json'}));
                if (ctx.mounted) update(() => results = r['results'] as List<dynamic>? ?? []);
              } catch (_) { if (ctx.mounted) update(() => results = []); }
            }),
          Expanded(child: ListView.builder(itemCount: results.length,
            itemBuilder: (_, i) {
              final item = results[i] as Map<String, dynamic>;
              return ListTile(title: Text(item['name'].toString()),
                subtitle: Text((item['country'] ?? '').toString()),
                onTap: () => Navigator.of(ctx).pop(item));
            })),
        ])),
      )),
    );
    input.dispose();
    if (!mounted || picked == null) return;
    setState(() {
      lat = (picked['latitude'] as num).toDouble();
      lon = (picked['longitude'] as num).toDouble();
      city = picked['name'].toString();
    });
    await _load();
  }

  static num val(Map<String, dynamic>? obj, String key, [int? i]) {
    final v = obj?[key];
    if (i != null) return v is List && i < v.length && v[i] is num ? v[i] as num : 0;
    return v is num ? v : 0;
  }
  static String fa(Object v) => v.toString().replaceAllMapped(
      RegExp(r'[0-9]'), (m) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(m.group(0)!)]);
  static String shamsi(String s) {
    final d = DateTime.tryParse(s);
    if (d == null) return s;
    final j = Jalali.fromDateTime(d);
    return j.formatter.wN + ' ' + fa(j.day) + ' ' + j.formatter.mN;
  }
  Widget card(Widget child) => Container(
    padding: const EdgeInsets.all(15),
    margin: const EdgeInsets.fromLTRB(14, 7, 14, 7),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17)),
    child: child);

  Widget days() {
    final daily = weather?['daily'] as Map<String, dynamic>?;
    final now = weather?['current'] as Map<String, dynamic>?;
    if (daily == null) return Center(child: Text(error ?? 'داده‌ای در دسترس نیست'));
    final dates = daily['time'] as List<dynamic>? ?? [];
    return RefreshIndicator(onRefresh: _load, child: ListView(children: [
      Container(margin: const EdgeInsets.all(14), padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xff19b9ec), blue]),
          borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('وضعیت فعلی', style: TextStyle(color: Colors.white)),
          Text(fa(val(now, 'temperature_2m').round()) + '°',
              style: const TextStyle(color: Colors.white, fontSize: 60)),
          Text('دمای احساسی ' + fa(val(now, 'apparent_temperature').round()) + '°',
              style: const TextStyle(color: Colors.white)),
          Text('رطوبت ' + fa(val(now, 'relative_humidity_2m').round()) + '٪',
              style: const TextStyle(color: Colors.white)),
        ])),
      card(const Text('پیش‌بینی ۱۴ روز آینده',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      ...List.generate(dates.length, (i) => card(Row(children: [
        const Icon(Icons.cloud_outlined, color: blue, size: 27),
        const SizedBox(width: 8),
        Expanded(child: Text(shamsi(dates[i].toString()))),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(fa(val(daily, 'temperature_2m_max', i).round()) + '° / ' +
              fa(val(daily, 'temperature_2m_min', i).round()) + '°',
            style: const TextStyle(fontWeight: FontWeight.w700)),
          Text('بارش ' + fa(val(daily, 'precipitation_probability_max', i).round()) + '٪'
              '  باد ' + fa(val(daily, 'wind_speed_10m_max', i).round()),
              style: const TextStyle(color: blue, fontSize: 11)),
        ]),
      ]))),
      const Padding(padding: EdgeInsets.all(18),
          child: Text('منبع پیش‌بینی: Open-Meteo. داده‌ها تخمینی هستند.',
              style: TextStyle(fontSize: 11))),
    ]));
  }

  Widget radarMap() => Stack(children: [
    FlutterMap(
      key: ValueKey(lat.toString() + ':' + lon.toString()),
      options: MapOptions(initialCenter: LatLng(lat, lon), initialZoom: 6),
      children: [
        TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.weatherglass.weather_glass'),
        if (layer && radar != null) TileLayer(urlTemplate: radar!,
          userAgentPackageName: 'com.weatherglass.weather_glass'),
        MarkerLayer(markers: [Marker(
          point: LatLng(lat, lon), width: 40, height: 40,
          child: const Icon(Icons.place, color: blue, size: 38))]),
      ],
    ),
    Positioned(top: 10, right: 10, left: 10, child: card(Row(children: [
      const Expanded(child: Text('لایه رادار بارش')),
      Switch(value: layer, onChanged: (v) => setState(() => layer = v)),
    ]))),
    Positioned(bottom: 12, right: 8, left: 8,
      child: card(Text(radar == null ? 'رادار در دسترس نیست' :
        '© OpenStreetMap contributors | RainViewer',
        textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)))),
  ]);

  Widget airInfo() {
    final c = air?['current'] as Map<String, dynamic>?;
    final aqi = val(c, 'us_aqi').round();
    return ListView(children: [
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('شاخص کیفیت هوا (US AQI)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(c == null ? 'ناموجود' : fa(aqi),
            style: const TextStyle(color: blue, fontSize: 50)),
        Text(c == null ? 'داده موجود نیست' :
             aqi <= 50 ? 'پاک' : aqi <= 100 ? 'قابل قبول' :
             aqi <= 150 ? 'ناسالم برای گروه‌های حساس' : 'ناسالم'),
      ])),
      card(Text('PM2.5: ' + fa(val(c, 'pm2_5')) + ' µg/m³')),
      card(Text('PM10: ' + fa(val(c, 'pm10')) + ' µg/m³')),
      card(const Text('داده‌ها از Open-Meteo Air Quality دریافت می‌شوند.')),
    ]);
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: const Color(0xfff2f8fc),
      appBar: AppBar(
        title: Text(city),
        actions: [
          IconButton(onPressed: _search, tooltip: 'انتخاب شهر',
              icon: const Icon(Icons.search)),
          IconButton(onPressed: _gps, tooltip: 'موقعیت فعلی',
              icon: const Icon(Icons.my_location)),
          IconButton(onPressed: busy ? null : _load,
              icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(children: [
        if (busy) const LinearProgressIndicator(),
        if (error != null) Padding(padding: const EdgeInsets.all(8),
            child: Text(error!, style: const TextStyle(color: Colors.red))),
        Expanded(child: IndexedStack(index: tab, children: [
          days(), radarMap(), airInfo(),
        ])),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calendar_month), label: '۱۴ روزه'),
          NavigationDestination(icon: Icon(Icons.radar), label: 'رادار'),
          NavigationDestination(icon: Icon(Icons.air), label: 'کیفیت هوا'),
        ],
      ),
    ),
  );
}
