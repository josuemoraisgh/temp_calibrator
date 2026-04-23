import 'package:flutter/material.dart';

import 'domain/sensor_model.dart';
import 'sensors/sensor_registry.dart';
import 'ui/sensor_calibration_page.dart';
import 'ui/theme/app_palette.dart';
import 'ui/theme/app_theme.dart';

void main() => runApp(const TempCalibratorApp());

class TempCalibratorApp extends StatelessWidget {
  const TempCalibratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Temp Sensor Calibrator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const ShellPage(),
    );
  }
}

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final sensors = SensorRegistry.sensors;
    final selected = sensors[_index];
    final wide = MediaQuery.sizeOf(context).width > 900;

    return Scaffold(
      backgroundColor: AppPalette.background,
      drawer: wide
          ? null
          : _SensorDrawer(
              sensors: sensors,
              index: _index,
              onSelect: (i) {
                setState(() => _index = i);
                Navigator.of(context).pop();
              },
            ),
      body: Column(
        children: [
          _AppHeader(
            sensor: selected,
            showMenu: !wide,
          ),
          Expanded(
            child: Row(
              children: [
                if (wide)
                  _SideNav(
                    sensors: sensors,
                    index: _index,
                    onSelect: (i) => setState(() => _index = i),
                  ),
                Expanded(
                  child: SensorCalibrationPage(
                    key: ValueKey(selected.id),
                    sensor: selected,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader({required this.sensor, required this.showMenu});
  final SensorModel sensor;
  final bool showMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppPalette.headerGradient),
      padding: const EdgeInsets.fromLTRB(18, 16, 24, 18),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (showMenu)
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: const Icon(Icons.science_outlined,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Temperature Sensor Calibrator',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Text(
                    'NTC · RTD · Termopares — ${sensor.displayName}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'WASM',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  const _SideNav({
    required this.sensors,
    required this.index,
    required this.onSelect,
  });
  final List<SensorModel> sensors;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AppPalette.surface,
        border: Border(right: BorderSide(color: AppPalette.border)),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 4, 8, 12),
            child: Text(
              'SENSORES',
              style: TextStyle(
                color: AppPalette.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          for (var i = 0; i < sensors.length; i++)
            _NavTile(
              sensor: sensors[i],
              selected: i == index,
              onTap: () => onSelect(i),
            ),
          const SizedBox(height: 24),
          const _Footer(),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.sensor,
    required this.selected,
    required this.onTap,
  });
  final SensorModel sensor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppPalette.forSensorId(sensor.id);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? color.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: selected ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(_iconFor(sensor.id), color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    sensor.displayName,
                    style: TextStyle(
                      color: selected
                          ? AppPalette.textPrimary
                          : AppPalette.textSecondary,
                      fontSize: 13.5,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.school_outlined,
                  size: 14, color: AppPalette.textMuted),
              const SizedBox(width: 6),
              Text(
                'LASEC · UFU',
                style: TextStyle(
                  color: AppPalette.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Calibração de sensores de temperatura',
            style: TextStyle(
              color: AppPalette.textMuted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorDrawer extends StatelessWidget {
  const _SensorDrawer({
    required this.sensors,
    required this.index,
    required this.onSelect,
  });
  final List<SensorModel> sensors;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppPalette.surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration:
                  const BoxDecoration(gradient: AppPalette.headerGradient),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.science_outlined, color: Colors.white, size: 28),
                  SizedBox(height: 10),
                  Text(
                    'Temp Calibrator',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'NTC · RTD · Termopares',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  for (var i = 0; i < sensors.length; i++)
                    _NavTile(
                      sensor: sensors[i],
                      selected: i == index,
                      onTap: () => onSelect(i),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconFor(String id) {
  if (id == 'ntc') return Icons.thermostat_auto;
  if (id == 'rtd') return Icons.cable;
  return Icons.flash_on;
}
