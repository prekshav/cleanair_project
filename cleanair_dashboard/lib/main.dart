import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: CleanAirDashboard(),
  ));
}

class CleanAirDashboard extends StatefulWidget {
  const CleanAirDashboard({super.key});

  @override
  State<CleanAirDashboard> createState() => _CleanAirDashboardState();
}

class _CleanAirDashboardState extends State<CleanAirDashboard> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  
  String _currentCityName = "Bengaluru";
  int _currentAqi = 74;
  LatLng _mapCenter = const LatLng(12.9716, 77.5946);
  final Set<Circle> _pollutionCircles = {};
  bool _isScanningHotspots = false;

  final List<Map<String, dynamic>> _mockLocationDatabase = [
    {
      "name": "Delhi",
      "coordinates": const LatLng(28.6139, 77.2090),
      "aqi": 320,
      "hotspots": [
        {"name": "Anand Vihar Corridor", "lat": 28.6468, "lng": 77.3160, "radius": 1500.0, "severity": "critical", "next_action": "Enforce strict odd-even vehicle access immediately."},
        {"name": "Connaught Place Ring", "lat": 28.6304, "lng": 77.2177, "radius": 1200.0, "severity": "heavy", "next_action": "Activate commercial street misting and restrict diesel trucks."}
      ],
      "predictions": [
        {"time": "06:00 AM", "aqi": 290, "trend": "Stable"},
        {"time": "12:00 PM", "aqi": 340, "trend": "Spike (Traffic)"},
        {"time": "06:00 PM", "aqi": 380, "trend": "Critical Spike"},
        {"time": "12:00 AM", "aqi": 310, "trend": "Settling"}
      ],
      "metrics": {"PM2.5": "245", "PM10": "390", "NO2": "85", "O3": "120", "CO": "2.4", "SO2": "45"}
    },
    {
      "name": "Mumbai",
      "coordinates": const LatLng(19.0760, 72.8777),
      "aqi": 165,
      "hotspots": [
        {"name": "Sion Junction Overpass", "lat": 19.0392, "lng": 72.8621, "radius": 1300.0, "severity": "heavy", "next_action": "Reroute industrial vehicles to peripheral highways."},
        {"name": "Andheri West Corridor", "lat": 19.1197, "lng": 72.8464, "radius": 1100.0, "severity": "moderate", "next_action": "Deploy localized mechanical street dust sweepers."}
      ],
      "predictions": [
        {"time": "06:00 AM", "aqi": 110, "trend": "Clearing"},
        {"time": "12:00 PM", "aqi": 155, "trend": "Moderate Rise"},
        {"time": "06:00 PM", "aqi": 190, "trend": "Peak Commute"},
        {"time": "12:00 AM", "aqi": 140, "trend": "Maritime Draft"}
      ],
      "metrics": {"PM2.5": "112", "PM10": "180", "NO2": "62", "O3": "55", "CO": "1.6", "SO2": "28"}
    },
    {
      "name": "Kolkata",
      "coordinates": const LatLng(22.5726, 88.3639),
      "aqi": 210,
      "hotspots": [
        {"name": "Howrah Approach Sector", "lat": 22.5851, "lng": 88.3416, "radius": 1400.0, "severity": "critical", "next_action": "Enforce anti-idling rules and continuous particulate misting."},
        {"name": "Exide Crossing Hub", "lat": 22.5442, "lng": 88.3475, "radius": 1000.0, "severity": "heavy", "next_action": "Initiate automated traffic filtering and green light extensions."}
      ],
      "predictions": [
        {"time": "06:00 AM", "aqi": 180, "trend": "Thermal Trap"},
        {"time": "12:00 PM", "aqi": 210, "trend": "Stable High"},
        {"time": "06:00 PM", "aqi": 245, "trend": "Evening Spike"},
        {"time": "12:00 AM", "aqi": 195, "trend": "Slow Dispersion"}
      ],
      "metrics": {"PM2.5": "155", "PM10": "240", "NO2": "70", "O3": "48", "CO": "1.9", "SO2": "34"}
    },
    {
      "name": "Bengaluru",
      "coordinates": const LatLng(12.9716, 77.5946),
      "aqi": 74,
      "hotspots": [
        {"name": "Silk Board Junction", "lat": 12.9176, "lng": 77.6244, "radius": 1000.0, "severity": "heavy", "next_action": "Deploy high-density shrub buffers and optimize transit signals."},
        {"name": "Whitefield Area", "lat": 12.9698, "lng": 77.7500, "radius": 1400.0, "severity": "moderate", "next_action": "Schedule factory emission audits and cycle-track expansion."}
      ],
      "predictions": [
        {"time": "06:00 AM", "aqi": 62, "trend": "Optimal"},
        {"time": "12:00 PM", "aqi": 85, "trend": "Moderate Rise"},
        {"time": "06:00 PM", "aqi": 95, "trend": "Peak Commute"},
        {"time": "12:00 AM", "aqi": 70, "trend": "Optimal"}
      ],
      "metrics": {"PM2.5": "42", "PM10": "68", "NO2": "30", "O3": "45", "CO": "0.8", "SO2": "12"}
    },
    {
      "name": "Chennai",
      "coordinates": const LatLng(13.0827, 80.2707),
      "aqi": 92,
      "hotspots": [
        {"name": "Kathipara Junction Arc", "lat": 13.0064, "lng": 80.2018, "radius": 1200.0, "severity": "moderate", "next_action": "Deploy air purification pillars and dynamic transit lanes."},
        {"name": "Manali Industrial Zone", "lat": 13.1667, "lng": 80.2667, "radius": 1600.0, "severity": "heavy", "next_action": "Initiate stack monitoring feedback loops on industrial burners."}
      ],
      "predictions": [
        {"time": "06:00 AM", "aqi": 75, "trend": "Good Base"},
        {"time": "12:00 PM", "aqi": 98, "trend": "Midday Rise"},
        {"time": "06:00 PM", "aqi": 115, "trend": "Slight Spike"},
        {"time": "12:00 AM", "aqi": 80, "trend": "Sea Breeze Draft"}
      ],
      "metrics": {"PM2.5": "55", "PM10": "95", "NO2": "40", "O3": "38", "CO": "1.1", "SO2": "22"}
    },
    {
      "name": "Hyderabad",
      "coordinates": const LatLng(17.3850, 78.4867),
      "aqi": 125,
      "hotspots": [
        {"name": "Gachibowli IT Corridor", "lat": 17.4401, "lng": 78.3489, "radius": 1100.0, "severity": "moderate", "next_action": "Incentivize office commuter vanpools and EV operations."},
        {"name": "Charminar Historic Core", "lat": 17.3616, "lng": 78.4747, "radius": 900.0, "severity": "heavy", "next_action": "Enforce pedestrian-only zones to reduce legacy soot accumulation."}
      ],
      "predictions": [
        {"time": "06:00 AM", "aqi": 90, "trend": "Stable"},
        {"time": "12:00 PM", "aqi": 130, "trend": "Traffic Influx"},
        {"time": "06:00 PM", "aqi": 150, "trend": "Peak Commute"},
        {"time": "12:00 AM", "aqi": 110, "trend": "Settling"}
      ],
      "metrics": {"PM2.5": "78", "PM10": "135", "NO2": "48", "O3": "52", "CO": "1.3", "SO2": "18"}
    }
  ];

  Map<String, dynamic> get _currentData => _mockLocationDatabase.firstWhere(
        (element) => element['name'].toString().toLowerCase() == _currentCityName.toLowerCase(),
        orElse: () => _mockLocationDatabase[3],
      );

  @override
  void initState() {
    super.initState();
    _generatePollutionZones(_mockLocationDatabase[3]); 
  }

  void _handleLocationSelect(Map<String, dynamic> locationData) {
    setState(() {
      _currentCityName = locationData['name'];
      _currentAqi = locationData['aqi'];
      _mapCenter = locationData['coordinates'];
      _searchController.text = _currentCityName;
      
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_mapCenter, 11.5),
      );
      _generatePollutionZones(locationData);
    });
  }

  void _generatePollutionZones(Map<String, dynamic> locationData) {
    _pollutionCircles.clear();
    final List<dynamic> hotspots = locationData['hotspots'];

    for (int i = 0; i < hotspots.length; i++) {
      final spot = hotspots[i];
      final Color zoneColor = spot['severity'] == 'critical' 
          ? Colors.red.withOpacity(0.35) 
          : spot['severity'] == 'heavy' 
              ? Colors.orange.withOpacity(0.35) 
              : Colors.yellow.withOpacity(0.30);

      _pollutionCircles.add(
        Circle(
          circleId: CircleId("${locationData['name']}_zone_$i"),
          center: LatLng(spot['lat'], spot['lng']),
          radius: spot['radius'],
          fillColor: zoneColor,
          strokeColor: zoneColor.withOpacity(0.8),
          strokeWidth: 2,
          consumeTapEvents: true,
          onTap: () => _showZoneActionDialog(spot['name'], spot['next_action'], locationData['metrics']),
        ),
      );
    }
  }

  void _triggerHiddenHotspotScan() async {
    setState(() => _isScanningHotspots = true);
    await Future.delayed(const Duration(seconds: 2)); 
    setState(() {
      _isScanningHotspots = false;
      _pollutionCircles.add(
        Circle(
          circleId: const CircleId("isolated_anomaly_zone"),
          center: LatLng(_mapCenter.latitude + 0.015, _mapCenter.longitude - 0.012),
          radius: 800.0,
          fillColor: Colors.purple.withOpacity(0.4),
          strokeColor: Colors.purple,
          strokeWidth: 3,
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🚨 Hidden Anomaly Mapped: Industrial sulfur trace isolated NW of baseline center!"),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _dispatchMunicipalCleanup(String locality, String operationalDirectives) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.engineering, color: Colors.teal, size: 40),
        title: const Text("Municipality Dispatch Service"),
        content: Text(
          "ALERTING DISPATCH CREWS:\n\n"
          "📍 Sector: $locality\n"
          "🚚 Payload: Heavy misting vehicles & sweepers assigned.\n"
          "📝 Directive: $operationalDirectives"
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Crew deployed to $locality successfully."), backgroundColor: Colors.green),
              );
            },
            child: const Text("Confirm Fleet Run", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _showZoneActionDialog(String areaName, String action, Map<String, dynamic> metrics) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(areaName, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("🚨 REASON & NEXT STEPS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Text(action, style: const TextStyle(fontSize: 15, height: 1.3)),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("PM₂.₅: ${metrics['PM2.5']} μg/m³"),
                Text("NO₂: ${metrics['NO2']} ppb"),
              ],
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  Color _getAqiColor(int aqi) {
    if (aqi > 300) return Colors.purple;
    if (aqi > 200) return Colors.red;
    if (aqi > 100) return Colors.amber;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _mapCenter, zoom: 11),
            onMapCreated: (controller) => _mapController = controller,
            circles: _pollutionCircles,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double targetWidth = constraints.maxWidth > 600 ? 480 : constraints.maxWidth * 0.92;
                
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Align(
                          alignment: Alignment.topLeft, // Align search box left too
                          child: _buildSearchModule(targetWidth),
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                          alignment: Alignment.bottomLeft, // CHANGED from bottomCenter to bottomLeft
                          child: SizedBox(
                            width: targetWidth, 
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _buildAqiRealTimeCard(),
                                const SizedBox(height: 12),
                                _buildStrategicActionDashboard(),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchModule(double constrainedWidth) {
    return SizedBox(
      width: constrainedWidth,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: TypeAheadField<Map<String, dynamic>>(
          controller: _searchController,
          builder: (context, controller, focusNode) => TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: "Search Indian Megacity...",
              prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
              suffixIcon: IconButton(
                icon: _isScanningHotspots 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.radar, color: Colors.purpleAccent),
                tooltip: "Scan Hidden Hotspots",
                onPressed: _triggerHiddenHotspotScan,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
          suggestionsCallback: (search) {
            return _mockLocationDatabase
                .where((loc) => loc['name'].toString().toLowerCase().contains(search.toLowerCase()))
                .toList();
          },
          itemBuilder: (context, location) {
            return ListTile(
              leading: const Icon(Icons.location_city, color: Colors.blueGrey),
              title: Text(location['name']),
              trailing: Text("AQI: ${location['aqi']}", 
                style: TextStyle(color: _getAqiColor(location['aqi']), fontWeight: FontWeight.bold),
              ),
            );
          },
          onSelected: (location) => _handleLocationSelect(location),
        ),
      ),
    );
  }

  Widget _buildAqiRealTimeCard() {
    final metrics = _currentData['metrics'];
    final List<dynamic> projections = _currentData['predictions'];

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: Colors.white.withOpacity(0.96),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Air Quality in $_currentCityName", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text("Real-Time Conditions & 24h Prediction", style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.analytics, color: Colors.blueAccent),
                  onPressed: () => _showDetailedMetricsGrid(metrics),
                )
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text("$_currentAqi", style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: _getAqiColor(_currentAqi))),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_currentAqi > 200 
                        ? "⚠️ HAZARDOUS REGIME" 
                        : _currentAqi > 100 
                            ? "⚠️ UNHEALTHY LEVELS" 
                            : "🌱 SATISFACTORY PARAMETERS",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _getAqiColor(_currentAqi)),
                      ),
                      const SizedBox(height: 2),
                      const Text("Baseline monitoring active.", style: TextStyle(fontSize: 11, color: Colors.black54)),
                    ],
                  ),
                )
              ],
            ),
            const Divider(height: 20),
            const Text("📈 24-HOUR INTERACTIVE PREDICTIONS TIMELINE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
            const SizedBox(height: 8),
            SizedBox(
              height: 62,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: projections.length,
                itemBuilder: (context, idx) {
                  final pred = projections[idx];
                  return Container(
                    width: 105,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _getAqiColor(pred['aqi']).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(pred['time'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        Text("AQI ${pred['aqi']}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getAqiColor(pred['aqi']))),
                        Text(pred['trend'], style: const TextStyle(fontSize: 9, color: Colors.black54), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showDetailedMetricsGrid(Map<String, dynamic> metrics) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Pollutant Analytical Metric Grid", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  _metricTile("PM₂.₅ & PM₁₀", "${metrics['PM2.5']} / ${metrics['PM10']} μg/m³", "Particulate matter concentrations."),
                  _metricTile("NO₂ (Toxic Gas)", "${metrics['NO2']} ppb", "Engine combustion metrics."),
                  _metricTile("O₃ (Smog Layer)", "${metrics['O3']} ppb", "Secondary environmental reactions."),
                  _metricTile("CO Gas", "${metrics['CO']} ppm", "Carbon monoxide outputs."),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricTile(String title, String data, String desc) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.blueGrey.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
          const SizedBox(height: 2),
          Text(data, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          Expanded(child: Text(desc, style: const TextStyle(fontSize: 9, color: Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildStrategicActionDashboard() {
    final List<dynamic> hotspots = _currentData['hotspots'];
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: Colors.white.withOpacity(0.96),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("🛠️ Municipality Control Matrix", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Column(
              children: hotspots.map<Widget>((spot) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.gpp_maybe, color: spot['severity'] == 'critical' ? Colors.red : Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(spot['name'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  GestureDetector(
                                    onTap: () => _dispatchMunicipalCleanup(spot['name'], spot['next_action']),
                                    child: const Text("DISPATCH CREW", style: TextStyle(fontSize: 10, color: Colors.teal, fontWeight: FontWeight.bold)),
                                  )
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text("Action: ${spot['next_action']}", style: const TextStyle(fontSize: 11, color: Colors.black87)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }
}