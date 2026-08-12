import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/location_service.dart';
import '../services/mosque_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class NearbyMosquesScreen extends StatefulWidget {
  const NearbyMosquesScreen({super.key});

  @override
  State<NearbyMosquesScreen> createState() => _NearbyMosquesScreenState();
}

enum _LoadState { loading, noLocation, noResults, error, done }

class _NearbyMosquesScreenState extends State<NearbyMosquesScreen> {
  _LoadState _state = _LoadState.loading;
  List<MosqueInfo> _mosques = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = _LoadState.loading);

    final position = await LocationService.getCurrentPosition();
    double? lat = position?.latitude;
    double? lng = position?.longitude;

    if (lat == null || lng == null) {
      // نستعمل آخر إحداثيات محفوظة (نفس المصدر المستعمل لأوقات الصلاة)
      // إن تعذّر تحديد الموقع الآن.
      final appState = context.read<AppState>();
      lat = appState.lastKnownLatitude;
      lng = appState.lastKnownLongitude;
    }

    if (lat == null || lng == null) {
      if (mounted) setState(() => _state = _LoadState.noLocation);
      return;
    }

    final results = await MosqueService.fetchNearby(latitude: lat, longitude: lng);
    if (!mounted) return;

    if (results == null) {
      setState(() => _state = _LoadState.error);
    } else if (results.isEmpty) {
      setState(() => _state = _LoadState.noResults);
    } else {
      setState(() {
        _mosques = results;
        _state = _LoadState.done;
      });
    }
  }

  Future<void> _openDirections(MosqueInfo m) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${m.latitude},${m.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أقرب مسجد')),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_state) {
      case _LoadState.loading:
        return const Center(child: CircularProgressIndicator());
      case _LoadState.noLocation:
        return _message(
          icon: Icons.location_off_outlined,
          text: 'تعذّر تحديد موقعك. تأكد من تفعيل خدمة الموقع والصلاحية، ثم أعد المحاولة.',
        );
      case _LoadState.error:
        return _message(
          icon: Icons.wifi_off_rounded,
          text: 'تعذّر الاتصال بالخادم. تحقق من الإنترنت وأعد المحاولة.',
        );
      case _LoadState.noResults:
        return _message(
          icon: Icons.mosque_outlined,
          text: 'لم نجد مساجد قريبة ضمن 3 كم. جرّب موقعًا آخر أو تحقق من الإنترنت.',
        );
      case _LoadState.done:
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _mosques.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final m = _mosques[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.mosque, color: AppColors.gold),
                title: Text(m.name),
                subtitle: Text(m.distanceLabel),
                trailing: IconButton(
                  icon: const Icon(Icons.directions, color: AppColors.sage),
                  tooltip: 'الاتجاهات',
                  onPressed: () => _openDirections(m),
                ),
              ),
            );
          },
        );
    }
  }

  Widget _message({required IconData icon, required String text}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }
}
