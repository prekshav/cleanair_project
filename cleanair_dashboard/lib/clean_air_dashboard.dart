import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class CleanAirDashboard extends StatefulWidget {
  const CleanAirDashboard({super.key});

  @override
  State<CleanAirDashboard> createState() => _CleanAirDashboardState();
}

class _CleanAirDashboardState extends State<CleanAirDashboard> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  
  // Current active city/location profile
  String _currentCityName = "Bengaluru";
  int _currentAqi = 74;
  LatLng _mapCenter = const LatLng(12.9716, 77.5946);
  final Set<Circle> _pollutionCircles = {};

  // Mock database simulating Places API responses alongside local spatial action coordinates
  final List<Map<String, dynamic>> _mockLocationDatabase = [
    {
      "name": "Delhi",
      "coordinates": const LatLng(28.6139, 77.2090),
      "aqi": 320,
      "hotspots": [
        {"name": "Anand Vihar Corridor", "lat": 28.6468, "lng": 77.3160, "radius": 1500.0, "severity": "critical", "next_action": "Enforce strict odd-even vehicle access immediately."},
        {"name": "Connaught Place Ring", "lat": 28.6304, "lng": 77.2177, "radius": 1200.0, "severity": "heavy", "next_action": "Activate commercial street misting and restrict diesel trucks."}
      ],
      "metrics": {"PM2.5": "245", "PM10": "390", "NO2": "85", "O3": "120", "CO": "2.4", "SO2": "45"}
    },
    {
      "name": "Bengaluru",
      "coordinates": const LatLng(12.9716, 77.5946),
      "aqi": 74,
      "hotspots": [
        {"name": "Silk Board Junction", "lat": 12.9176, "lng": 77.6244, "radius": 1000.0, "severity": "heavy", "next_action": "Deploy high-density shrub buffers and optimize transit signals."},
        {"name": "Whitefield Industrial Area", "lat": 12.9698, "lng": 77.7500, "radius": 1400.0, "severity": "moderate", "next_action": "Schedule factory emission audits and cycle-track expansion."}
      ],
      "metrics": {"PM2.5": "42", "PM10": "68", "NO2": "30", "O3": "45", "CO": "0.8", "SO2": "12"}
    }
  ];

  Map<String, dynamic> get _currentData => _mockLocationDatabase.firstWhere(
        (element) => element['name'].toString().toLowerCase() == _currentCityName.toLowerCase(),
        orElse: () => _mockLocationDatabase[1], // Default to Bengaluru
      );

  @override
  void initState() {
    super.initState();
    _generatePollutionZones(_mockLocationDatabase[1]); // Init with Bengaluru
  }

  void _handleLocationSelect(Map<String, dynamic> locationData) {
    setState(() {
      _currentCityName = locationData['name'];
      _currentAqi = locationData['aqi'];
      _mapCenter = locationData['coordinates'];
      _searchController.text = _currentCityName;
      
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_mapCenter, 12.5),
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

  void _showZoneActionDialog(String areaName, String action, Map<String, dynamic> metrics) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text(areaName, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("🚨 AREA-WISE CRITICAL ACTION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Text(action, style: const TextStyle(fontSize: 15, height: 1.3)),
            const Divider(height: 24),
            const Text("Local Context Metrics:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Dismiss")),
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
          // 0. Base Map Layer
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _mapCenter, zoom: 12),
            onMapCreated: (controller) => _mapController = controller,
            circles: _pollutionCircles,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // 1. Interactive UI Shell overlay
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Top Search Block
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: _buildSearchModule(),
                  ),
                ),
                
                // Dashboard Cards Wrapper
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Spacer(),
                        _buildAqiRealTimeCard(),
                        const SizedBox(height: 12),
                        _buildStrategicActionDashboard(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Core Components Modules ---

  Widget _buildSearchModule() {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85, // Medium sized alignment
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          child: TypeAheadField<Map<String, dynamic>>(
            controller: _searchController,
            builder: (context, controller, focusNode) => TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: "Search city or neighborhood...",
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.my_location, color: Colors.blueAccent),
                  onPressed: () {
                    // Quick-return tracking to current localized profile (Bengaluru in setup)
                    _handleLocationSelect(_mockLocationDatabase[1]); //
                  },
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
      ),
    );
  }

  Widget _buildAqiRealTimeCard() {
    final metrics = _currentData['metrics'];
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: Colors.white.withOpacity(0.95),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Air Quality in $_currentCityName", 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    const Text("Real-Time Spatial Diagnostics Feed", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.blueAccent),
                  onPressed: () => _showDetailedMetricsGrid(metrics),
                )
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text("$_currentAqi", 
                  style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: _getAqiColor(_currentAqi)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentAqi > 200 ? "⚠️ CRITICAL HAZARD" : "🌱 SATISFACTORY",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _getAqiColor(_currentAqi)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentAqi > 200 
                          ? "Atmospheric criteria load requires structural enforcement limits." 
                          : "Air quality ambient concentrations are within clean parameters.",
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                )
              ],
            ),
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
            const Text("Pollutant Analytical Detail Grid", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  _metricTile("PM₂.₅ & PM₁₀", "${metrics['PM2.5']} / ${metrics['PM10']} μg/m³", "Particulate matter generated primarily from vehicle combustion and ambient road dust resuspension."),
                  _metricTile("NO₂ (Toxic)", "${metrics['NO2']} ppb", "Toxic gas concentrations originating from internal fossil vehicle exhaust structures."),
                  _metricTile("O₃ (Smog)", "${metrics['O3']} ppb", "Ground level secondary photochemical smog formed via chemical reaction under sunlight."),
                  _metricTile("CO Gas", "${metrics['CO']} ppm", "Carbon Monoxide gas, highly harmful byproduct tracking incomplete fuel combustion structures."),
                  _metricTile("SO₂ Gas", "${metrics['SO2']} ppb", "Sulfur Dioxide indicators emitted directly by manufacturing industrial processes & fossil fuels."),
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 2),
          Text(data, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          Expanded(child: Text(desc, style: const TextStyle(fontSize: 9, color: Colors.black54), maxLines: 3, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildStrategicActionDashboard() {
    final List<dynamic> hotspots = _currentData['hotspots'];
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: Colors.white.withOpacity(0.95),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("🛠️ Strategic City Action Matrix", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            // Live Transparency Feed Module
            Row(
              children: [
                const Icon(Icons.circle, size: 12, color: Colors.greenAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Public Transparency Status: ${hotspots.length} active targeted zone areas discovered inside $_currentCityName.",
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.blueGrey),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Map Area Index Navigation Indicators
            const Text("Tap map circles or read details below to discover localized metrics:", style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                        Icon(Icons.location_searching, 
                          color: spot['severity'] == 'critical' ? Colors.red : Colors.orange, size: 18
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(spot['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text("Action View: ${spot['next_action']}", style: const TextStyle(fontSize: 11, color: Colors.black87)),
                              const SizedBox(height: 4),
                              Row(
                                children: const [
                                  Icon(Icons.commute, size: 12, color: Colors.indigo),
                                  SizedBox(width: 4),
                                  Text("Traffic: Restrictions suggested", style: TextStyle(fontSize: 10, color: Colors.indigo)),
                                  SizedBox(width: 12),
                                  Icon(Icons.park, size: 12, color: Colors.green),
                                  SizedBox(width: 4),
                                  Text("Infrastructure: Filter buffer zone", style: TextStyle(fontSize: 10, color: Colors.green)),
                                ],
                              )
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