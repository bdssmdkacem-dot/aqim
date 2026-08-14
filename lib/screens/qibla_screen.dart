import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/location_service.dart';
import '../theme/app_theme.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  Position? _position;
  bool _loading = true;
  String? _locationError;

  static const double _kaabaLat = 21.422487;
  static const double _kaabaLon = 39.826206;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _locationError = null;
      });
    }

    final position = await LocationService.getCurrentPosition();
    if (!mounted) return;

    setState(() {
      _position = position;
      _loading = false;
      _locationError = position == null
          ? 'فعّل خدمة الموقع واسمح لأقم باستخدام موقعك لحساب اتجاه القبلة.'
          : null;
    });
  }

  Future<void> _openLocationSettings() async {
    await Geolocator.openLocationSettings();
    await _loadLocation();
  }

  double _qiblaBearing(double latitude, double longitude) {
    final lat1 = _degToRad(latitude);
    final lat2 = _degToRad(_kaabaLat);
    final deltaLon = _degToRad(_kaabaLon - longitude);

    final x = math.sin(deltaLon) * math.cos(lat2);
    final y = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLon);

    return _normalize(math.atan2(x, y) * 180 / math.pi);
  }

  double _degToRad(double value) => value * math.pi / 180;

  double _normalize(double value) => (value % 360 + 360) % 360;

  double _relativeAngle(double qibla, double heading) {
    var angle = qibla - heading;
    while (angle > 180) angle -= 360;
    while (angle < -180) angle += 360;
    return angle;
  }

  String _directionName(double degrees) {
    final dirs = ['شمال', 'شمال شرقي', 'شرق', 'جنوب شرقي', 'جنوب', 'جنوب غربي', 'غرب', 'شمال غربي'];
    final index = ((degrees + 22.5) / 45).floor() % 8;
    return dirs[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        title: Text('تحديد القبلة', style: GoogleFonts.amiri(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : _position == null
                ? _LocationRequired(
                    message: _locationError ?? 'تعذر تحديد موقعك.',
                    onRetry: _loadLocation,
                    onSettings: _openLocationSettings,
                  )
                : _CompassView(
                    position: _position!,
                    qiblaBearing: _qiblaBearing(_position!.latitude, _position!.longitude),
                    relativeAngle: _relativeAngle,
                    directionName: _directionName,
                  ),
      ),
    );
  }
}

class _CompassView extends StatelessWidget {
  final Position position;
  final double qiblaBearing;
  final double Function(double qibla, double heading) relativeAngle;
  final String Function(double degrees) directionName;

  const _CompassView({
    required this.position,
    required this.qiblaBearing,
    required this.relativeAngle,
    required this.directionName,
  });

  @override
  Widget build(BuildContext context) {
    final stream = FlutterCompass.events;

    if (stream == null) {
      return _SensorUnavailable(
        qiblaBearing: qiblaBearing,
        directionName: directionName,
      );
    }

    return StreamBuilder<CompassEvent>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _SensorUnavailable(
            qiblaBearing: qiblaBearing,
            directionName: directionName,
          );
        }

        final heading = snapshot.data?.heading;
        if (heading == null) {
          return _SensorUnavailable(
            qiblaBearing: qiblaBearing,
            directionName: directionName,
          );
        }

        final angle = relativeAngle(qiblaBearing, heading);
        final accuracy = snapshot.data?.accuracy;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            children: [
              Text('اتجه بالهاتف حتى يشير السهم إلى الكعبة', textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 14, color: AppColors.inkSoft)),
              const SizedBox(height: 18),
              Container(
                width: 310,
                height: 310,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceDark,
                  border: Border.all(color: AppColors.gold.withOpacity(.55), width: 2),
                  boxShadow: [
                    BoxShadow(color: AppColors.gold.withOpacity(.10), blurRadius: 35, spreadRadius: 6),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Positioned(top: 22, child: Text('شمال', style: TextStyle(color: AppColors.ivory, fontWeight: FontWeight.w800))),
                    const Positioned(bottom: 22, child: Text('جنوب', style: TextStyle(color: AppColors.inkSoft))),
                    const Positioned(left: 22, child: Text('غرب', style: TextStyle(color: AppColors.inkSoft))),
                    const Positioned(right: 22, child: Text('شرق', style: TextStyle(color: AppColors.inkSoft))),
                    Transform.rotate(
                      angle: angle * math.pi / 180,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.navigation_rounded, color: AppColors.gold, size: 108),
                          Transform.translate(
                            offset: const Offset(0, -12),
                            child: const Icon(Icons.mosque_rounded, color: AppColors.ivory, size: 30),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold.withOpacity(.30)),
                ),
                child: Column(
                  children: [
                    Text('${qiblaBearing.toStringAsFixed(0)}°', style: GoogleFonts.tajawal(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.gold)),
                    const SizedBox(height: 3),
                    Text(directionName(qiblaBearing), style: GoogleFonts.cairo(color: AppColors.ivory, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('اتجاه القبلة من موقعك الحالي', style: GoogleFonts.cairo(fontSize: 11, color: AppColors.inkSoft)),
                    if (accuracy != null) ...[
                      const SizedBox(height: 5),
                      Text('دقة البوصلة: ±${accuracy!.toStringAsFixed(0)}°', style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textMuted)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text('إذا كان السهم يتذبذب، حرّك الهاتف على شكل رقم 8 لمعايرة البوصلة وأبعده عن المعادن والمغناطيس.', textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 11, height: 1.7, color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Text('${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}', style: GoogleFonts.tajawal(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        );
      },
    );
  }
}

class _LocationRequired extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSettings;

  const _LocationRequired({required this.message, required this.onRetry, required this.onSettings});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off_rounded, color: AppColors.gold, size: 58),
              const SizedBox(height: 18),
              Text('نحتاج إلى موقعك', style: GoogleFonts.amiri(fontSize: 25, fontWeight: FontWeight.w800, color: AppColors.ivory)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 13, height: 1.7, color: AppColors.inkSoft)),
              const SizedBox(height: 18),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onRetry, child: const Text('السماح بالموقع'))),
              const SizedBox(height: 8),
              TextButton(onPressed: onSettings, child: const Text('فتح إعدادات الموقع')),
            ],
          ),
        ),
      );
}

class _SensorUnavailable extends StatelessWidget {
  final double qiblaBearing;
  final String Function(double degrees) directionName;

  const _SensorUnavailable({required this.qiblaBearing, required this.directionName});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.explore_off_rounded, color: AppColors.gold, size: 62),
              const SizedBox(height: 18),
              Text('البوصلة غير متوفرة في هذا الجهاز', textAlign: TextAlign.center, style: GoogleFonts.amiri(fontSize: 23, fontWeight: FontWeight.w800, color: AppColors.ivory)),
              const SizedBox(height: 10),
              Text('هذا الجهاز لا يوفّر حساس اتجاه مغناطيسي يمكن للتطبيق قراءته. لا يمكن إعطاء سهم حيّ دقيق دون هذا الحساس.', textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 12.5, height: 1.7, color: AppColors.inkSoft)),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.gold.withOpacity(.3))),
                child: Column(children: [
                  Text('${qiblaBearing.toStringAsFixed(0)}°', style: GoogleFonts.tajawal(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.gold)),
                  Text('من الشمال — ${directionName(qiblaBearing)}', style: GoogleFonts.cairo(color: AppColors.ivory)),
                  const SizedBox(height: 6),
                  Text('يمكن استخدام هذه الزاوية مع بوصلة خارجية.', textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textMuted)),
                ]),
              ),
            ],
          ),
        ),
      );
}
