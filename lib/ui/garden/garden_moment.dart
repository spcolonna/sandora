part of 'garden_view.dart';

IconData _weatherIcon(Weather w, DayPhase phase) => switch (w) {
  Weather.clear => switch (phase) {
    DayPhase.night => Icons.nightlight_round,
    DayPhase.day => Icons.wb_sunny_rounded,
    _ => Icons.wb_twilight_rounded,
  },
  Weather.cloudy => Icons.cloud_rounded,
  Weather.rain => Icons.water_drop_rounded,
  Weather.storm => Icons.thunderstorm_rounded,
  Weather.fog => Icons.foggy,
  Weather.snow => Icons.ac_unit_rounded,
};

/// Momento del día, clima y, si hay, el regalo que dejaron en el jardín. Se
/// toca para ver qué pasa y elegir el clima de donde está el jugador.
class MomentChip extends StatelessWidget {
  final DateTime now;
  final Weather weather;
  const MomentChip({super.key, required this.now, required this.weather});

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final phase = p.dayCycle.phaseAt(now);
    final after = _rainbowTime(now);
    final gifts = p.dayCycle.giftsAt(now, weather, afterRain: after);
    final left = gifts.fold(0, (n, g) => n + p.giftsLeft(g, weather: weather, afterRain: after, now: now));
    final open = gifts.where((g) => p.giftsLeft(g, weather: weather, afterRain: after, now: now) > 0).firstOrNull;
    return GestureDetector(
      onTap: () => _showNowSheet(context, now: now, weather: weather),
      child: Glass(
        radius: BorderRadius.circular(16),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _weatherIcon(weather, phase),
              size: 16,
              color: weather == Weather.clear && phase != DayPhase.night ? Palette.lantern : Palette.dusk,
            ),
            const SizedBox(width: 6),
            Text(
              weather == Weather.clear ? tr('moment.${phase.name}') : tr('weather.${weather.name}'),
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
            if (open != null) ...[
              const SizedBox(width: 6),
              Text('· ${tr('gift.${open.id}')} ×$left', style: const TextStyle(fontSize: 12.5)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Qué pasa ahora en el jardín (momento, clima, regalos) y la opción de usar
/// el clima de donde está el jugador.
Future<void> _showNowSheet(BuildContext context, {required DateTime now, required Weather weather}) {
  return showWashiSheet(
    context,
    builder: (context) => ListenableBuilder(
      listenable: WeatherService.instance,
      builder: (context, _) {
        final text = Theme.of(context).textTheme;
        final ws = WeatherService.instance;
        final p = Progress.instance;
        final phase = p.dayCycle.phaseAt(now);
        final w = ws.at(now);
        final gifts = p.dayCycle.giftsAt(now, w, afterRain: _rainbowTime(now));
        final hint = gifts.isEmpty ? tr('moment.${phase.name}.hint') : tr('gift.${gifts.first.id}.hint');
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Text(tr('weather.title'), style: text.titleLarge)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(_weatherIcon(w, phase), color: Palette.wood),
                    const SizedBox(width: 12),
                    Text('${tr('moment.${phase.name}')} · ${tr('weather.${w.name}')}', style: text.titleSmall),
                  ],
                ),
                const SizedBox(height: 8),
                Text(hint, style: text.bodyMedium),
                const SizedBox(height: 8),
                InkToggleRow(
                  title: tr('weather.real.title'),
                  subtitle: ws.useReal ? tr('weather.real.desc') : '${tr('weather.own')} ${tr('weather.real.desc')}',
                  value: ws.useReal,
                  onChanged: (on) async {
                    if (!on) return ws.disableReal();
                    final result = await ws.enableReal();
                    if (result == RealWeatherResult.ok || !context.mounted) return;
                    showWashiToast(
                      context,
                      tr(result == RealWeatherResult.denied ? 'weather.real.denied' : 'weather.real.failed'),
                    );
                  },
                ),
                if (ws.isReal(now)) Text(tr('weather.source'), style: text.bodySmall),
              ],
            ),
          ),
        );
      },
    ),
  );
}
