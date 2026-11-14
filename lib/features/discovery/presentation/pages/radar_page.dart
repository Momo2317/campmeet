import 'package:camp_meet/features/discovery/presentation/pages/discovery_page.dart'
    show BottomNavBar;
import 'package:camp_meet/core/theme/app_theme.dart';
import 'dart:math';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camp_meet/features/discovery/data/student_model.dart';
import 'package:camp_meet/features/discovery/data/radar_repository.dart';
import 'package:camp_meet/features/discovery/presentation/pages/student_profile_page.dart';
import 'package:camp_meet/features/profile/data/user_profile_repository.dart';

class RadarPage extends ConsumerStatefulWidget {
  const RadarPage({super.key});

  @override
  ConsumerState<RadarPage> createState() => _RadarPageState();
}

class _RadarPageState extends ConsumerState<RadarPage> {
  final MapController _mapController = MapController();
  final LatLng _campusCenter =
      const LatLng(52.5122, 13.3268); // TU Berlin Hauptcampus

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  String _selectedFilter = 'campus'; // 'campus', 'events', 'study', 'anschluss'

  // Lokalisierte Hotspots um den Campus
  final List<LatLng> _hotspots = [
    const LatLng(52.5122, 13.3268), // Hauptgebäude
    const LatLng(52.5115, 13.3255), // Mensa
    const LatLng(52.5132, 13.3280), // Bibliothek
    const LatLng(52.5105, 13.3295), // Café / Campus-Wiese
  ];

  @override
  Widget build(BuildContext context) {
    final allPins = ref.watch(radarPinsProvider);
    final userProfile = ref.watch(userProfileProvider);

    return Scaffold(
      bottomNavigationBar: const SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: BottomNavBar(selected: 'radar'),
        ),
      ),
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Radar',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: Colors.white,
            shadows: [const Shadow(color: Colors.black87, blurRadius: 10)],
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(CupertinoIcons.location_fill,
                    color: Colors.white),
                onPressed: () => _mapController.move(_campusCenter, 16.5),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _campusCenter,
              initialZoom: 16.0,
              onTap: (_, __) {
                if (_sheetController.isAttached &&
                    _sheetController.size > 0.17) {
                  _sheetController.animateTo(0.16,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut);
                }
              },
              maxZoom: 20.0,
              minZoom: 6.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: context.isDark
                    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                    : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.camp_meet',
              ),
              CircleLayer(
                circles: _hotspots.map((latlng) {
                      return CircleMarker(
                        point: latlng,
                        color: const Color(0xFF9B30FF).withOpacity(0.12),
                        borderStrokeWidth: 0,
                        radius: 120,
                        useRadiusInMeter: true,
                      );
                    }).toList() +
                    _hotspots.map((latlng) {
                      return CircleMarker(
                        point: latlng,
                        color: const Color(0xFFFF2D9B).withOpacity(0.2),
                        borderStrokeWidth: 0,
                        radius: 60,
                        useRadiusInMeter: true,
                      );
                    }).toList(),
              ),
              MarkerLayer(
                markers: _buildActiveMarkers(allPins),
              ),
            ],
          ),

          // Fadenkreuz für das Setzen eigener Pins
          IgnorePointer(
            child: Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.location_solid,
                      color: Color(0xFF9B30FF), size: 38),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.24),
                          width: 0.8),
                    ),
                    child: Text('Position im Fokus',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),

          // Button zum Erstellen eines neuen Radar-Pins
          Positioned(
            top: 100,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: () =>
                  _showCreateDialog(context, userProfile?.name ?? 'Student'),
              backgroundColor: const Color(0xFF9B30FF),
              icon: Icon(CupertinoIcons.add, color: Colors.white),
              label: Text('Pin setzen',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),

          // Draggable Bottom Sheet für Live-Radar Liste
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.35,
            minChildSize: 0.16,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              final activePins = _filterPins(allPins);

              return Container(
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 16)],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        final open = _sheetController.size > 0.6;
                        _sheetController.animateTo(open ? 0.35 : 0.85,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut);
                      },
                      onVerticalDragUpdate: (d) {
                        final h = MediaQuery.of(context).size.height;
                        _sheetController.jumpTo(
                            (_sheetController.size - d.delta.dy / h)
                                .clamp(0.16, 0.85));
                      },
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                  color: context.fgA(0.24),
                                  borderRadius: BorderRadius.circular(2))),
                          const SizedBox(height: 14),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                      color: const Color(0xFF2BD9A0),
                                      shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Text('Campus Radar Live',
                                    style: TextStyle(
                                        color: context.fg,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Text('${activePins.length} Aktiv',
                                    style: TextStyle(
                                        color: context.fgA(0.54),
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _FilterChip(
                              label: 'Alle',
                              isSelected: _selectedFilter == 'campus',
                              onTap: () =>
                                  setState(() => _selectedFilter = 'campus')),
                          _FilterChip(
                              label: 'Events',
                              isSelected: _selectedFilter == 'events',
                              onTap: () =>
                                  setState(() => _selectedFilter = 'events')),
                          _FilterChip(
                              label: 'Study',
                              isSelected: _selectedFilter == 'study',
                              onTap: () =>
                                  setState(() => _selectedFilter = 'study')),
                          _FilterChip(
                              label: 'Anschluss',
                              isSelected: _selectedFilter == 'anschluss',
                              onTap: () => setState(
                                  () => _selectedFilter = 'anschluss')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: activePins.isEmpty
                          ? Center(
                              child: Text('Keine Pins in dieser Kategorie',
                                  style: TextStyle(color: context.fgA(0.38))),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding:
                                  const EdgeInsets.fromLTRB(16, 4, 16, 100),
                              itemCount: activePins.length,
                              itemBuilder: (context, index) {
                                final pin = activePins[index];
                                return _buildPinCard(
                                    pin, userProfile?.id ?? 'me');
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<RadarPin> _filterPins(List<RadarPin> allPins) {
    if (_selectedFilter == 'campus') return allPins;
    return allPins.where((p) => p.category == _selectedFilter).toList();
  }

  List<Marker> _buildActiveMarkers(List<RadarPin> allPins) {
    final filtered = _filterPins(allPins);
    final userProfile = ref.read(userProfileProvider);

    return filtered.map((pin) {
      final point = LatLng(pin.latitude, pin.longitude);
      final isEvent = pin.category == 'events';
      final isStudy = pin.category == 'study';
      final color = isEvent
          ? const Color(0xFF9B30FF)
          : (isStudy ? const Color(0xFF3FA7FF) : const Color(0xFFFF2D9B));
      final icon = isEvent
          ? CupertinoIcons.flame_fill
          : (isStudy ? CupertinoIcons.book_fill : CupertinoIcons.heart_fill);

      return Marker(
        point: point,
        width: 130,
        height: 64,
        child: GestureDetector(
          onTap: () {
            _mapController.move(point, 18.0);
            _showPinDetailSheet(pin, userProfile?.id ?? 'me');
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.35), blurRadius: 8)
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 14),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 85),
                      child: Text(
                        pin.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(CupertinoIcons.arrowtriangle_down_fill,
                  color: color, size: 20),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildPinCard(RadarPin pin, String myUserId) {
    final isEvent = pin.category == 'events';
    final isStudy = pin.category == 'study';
    final color = isEvent
        ? const Color(0xFF9B30FF)
        : (isStudy ? const Color(0xFF3FA7FF) : const Color(0xFFFF2D9B));
    final icon = isEvent
        ? CupertinoIcons.flame_fill
        : (isStudy ? CupertinoIcons.book_fill : CupertinoIcons.heart_fill);
    final pos = LatLng(pin.latitude, pin.longitude);
    final isJoined = pin.joinedUserIds.contains(myUserId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: context.fgA(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(pin.title,
            style: TextStyle(
                color: context.fg, fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(pin.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.fgA(0.6), fontSize: 13)),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('${pin.participantCount} dabei',
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                if (pin.timeString != null) ...[
                  const SizedBox(width: 10),
                  Text('• ${pin.timeString}',
                      style: TextStyle(color: context.fgA(0.38), fontSize: 11)),
                ],
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(CupertinoIcons.scope, color: color),
          onPressed: () {
            _mapController.move(pos, 18.0);
            _showPinDetailSheet(pin, myUserId);
          },
        ),
        onTap: () => _showPinDetailSheet(pin, myUserId),
      ),
    );
  }

  void _showPinDetailSheet(RadarPin pin, String myUserId) {
    final isJoined = pin.joinedUserIds.contains(myUserId);
    final isEvent = pin.category == 'events';
    final color = isEvent
        ? const Color(0xFF9B30FF)
        : (pin.category == 'study'
            ? const Color(0xFF3FA7FF)
            : const Color(0xFFFF2D9B));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: context.fgA(0.24),
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(pin.category.toUpperCase(),
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 11)),
                  ),
                  const Spacer(),
                  Text('Erstellt von: ${pin.creatorName}',
                      style: TextStyle(color: context.fgA(0.38), fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              Text(pin.title,
                  style: TextStyle(
                      color: context.fg,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              if (pin.timeString != null) ...[
                const SizedBox(height: 4),
                Text('${pin.timeString}',
                    style: TextStyle(color: context.fgA(0.7), fontSize: 14)),
              ],
              const SizedBox(height: 14),
              Text(pin.description,
                  style: TextStyle(
                      color: context.fgA(0.6), fontSize: 14, height: 1.4)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: context.fgA(0.04),
                    borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.person_2_fill, color: context.fgA(0.7)),
                    const SizedBox(width: 10),
                    Text('${pin.participantCount} Studierende nehmen teil',
                        style: TextStyle(
                            color: context.fg, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref
                            .read(radarPinsProvider.notifier)
                            .toggleJoinPin(pin.id, myUserId);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isJoined
                                ? 'Teilnahme zurückgezogen'
                                : 'Du bist jetzt dabei!'),
                            backgroundColor: const Color(0xFF9B30FF),
                          ),
                        );
                      },
                      icon: Icon(
                          isJoined
                              ? CupertinoIcons.checkmark_circle_fill
                              : CupertinoIcons.plus_circle,
                          color: Colors.white),
                      label: Text(
                          isJoined ? 'Dabei! (Verlassen)' : 'Ich bin dabei',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isJoined ? context.fgA(0.25) : color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    onPressed: () {
                      _mapController.move(
                          LatLng(pin.latitude, pin.longitude), 18.0);
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(CupertinoIcons.location_north_fill),
                    style: IconButton.styleFrom(
                        backgroundColor: context.fgA(0.12),
                        foregroundColor: context.fg),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, String userName) {
    String selectedCategory = 'events';
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final timeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInsets = MediaQuery.of(context).viewInsets.bottom;
            return Container(
              padding: EdgeInsets.fromLTRB(
                  24, 20, 24, bottomInsets > 0 ? bottomInsets + 24 : 36),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                              color: context.fgA(0.24),
                              borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 18),
                  Text('Neuen Pin am Campus setzen',
                      style: TextStyle(
                          color: context.fg,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                      'Der Pin wird genau an die Position des Fadenkreuzes gesetzt.',
                      style: TextStyle(color: context.fgA(0.54), fontSize: 13)),
                  const SizedBox(height: 18),

                  // Typ-Auswahl
                  Row(
                    children: [
                      Expanded(
                        child: _buildTypeButton(
                          label: 'Event',
                          isSelected: selectedCategory == 'events',
                          color: const Color(0xFF9B30FF),
                          onTap: () =>
                              setModalState(() => selectedCategory = 'events'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTypeButton(
                          label: 'Study',
                          isSelected: selectedCategory == 'study',
                          color: const Color(0xFF3FA7FF),
                          onTap: () =>
                              setModalState(() => selectedCategory = 'study'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTypeButton(
                          label: 'Treff',
                          isSelected: selectedCategory == 'anschluss',
                          color: const Color(0xFFFF2D9B),
                          onTap: () => setModalState(
                              () => selectedCategory = 'anschluss'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Titel
                  TextField(
                    controller: titleController,
                    style: TextStyle(color: context.fg),
                    decoration: InputDecoration(
                      hintText: 'Titel (z.B. Mathe 1 Lerngruppe / Grillen)',
                      hintStyle: TextStyle(color: context.fgA(0.38)),
                      filled: true,
                      fillColor: context.fgA(0.05),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Zeit
                  TextField(
                    controller: timeController,
                    style: TextStyle(color: context.fg),
                    decoration: InputDecoration(
                      hintText: 'Uhrzeit / Zeitraum (z.B. Heute ab 19:00)',
                      hintStyle: TextStyle(color: context.fgA(0.38)),
                      filled: true,
                      fillColor: context.fgA(0.05),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Beschreibung
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    style: TextStyle(color: context.fg),
                    decoration: InputDecoration(
                      hintText: 'Details (z.B. Wo genau, was mitbringen?)',
                      hintStyle: TextStyle(color: context.fgA(0.38)),
                      filled: true,
                      fillColor: context.fgA(0.05),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        final title = titleController.text.trim();
                        final desc = descController.text.trim();
                        final time = timeController.text.trim();

                        if (title.isEmpty || desc.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Bitte Titel und Details ausfüllen.')),
                          );
                          return;
                        }

                        // Kartenzentrum holen
                        final center = _mapController.camera.center;
                        final newPin = RadarPin(
                          id: 'pin_${DateTime.now().millisecondsSinceEpoch}',
                          title: title,
                          description: desc,
                          category: selectedCategory,
                          latitude: center.latitude,
                          longitude: center.longitude,
                          creatorName: userName,
                          timeString: time.isNotEmpty ? time : 'Jetzt',
                        );

                        ref.read(radarPinsProvider.notifier).addPin(newPin);
                        setState(() => _selectedFilter = selectedCategory);

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Pin "$title" gesetzt'),
                            backgroundColor: const Color(0xFF9B30FF),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9B30FF),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22)),
                      ),
                      child: Text('Pin veröffentlichen',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTypeButton({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : context.fgA(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.7)
                  : context.fgA(0.12)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : context.fgA(0.6),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF9B30FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? Colors.transparent : context.fgA(0.14)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : context.fgA(0.7),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
