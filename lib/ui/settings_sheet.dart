import 'dart:io';

import 'package:flutter/material.dart';

import 'widgets/washi.dart';

import '../balance/balance.dart';
import '../i18n/i18n.dart';
import '../garden/cloud_save.dart';
import '../garden/progress.dart';
import '../garden/reminders.dart';
import '../garden/weather_service.dart';
import '../settings.dart';
import 'fx/sfx.dart';
import 'garden/garden_gate.dart';
import 'garden_screen.dart';
import 'theme/palette.dart';
import 'title_intro.dart';

Future<void> showSettingsSheet(BuildContext context) {
  return showWashiSheet(
    context,
    isScrollControlled: true,
    builder: (context) => ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final s = AppSettings.instance;
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    tr('settings.title'),
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  InkToggleRow(title: tr('settings.sound'), value: s.sound, onChanged: s.setSound),
                  InkToggleRow(
                    title: tr('settings.music'),
                    value: s.music,
                    onChanged: (v) {
                      s.setMusic(v);
                      if (v) {
                        SoundBoard.instance.loop(Ambience.wind, volume: 0.18);
                        SoundBoard.instance.music();
                      } else {
                        SoundBoard.instance.stopAllLoops();
                      }
                    },
                  ),
                  InkToggleRow(title: tr('settings.haptics'), value: s.haptics, onChanged: s.setHaptics),
                  InkToggleRow(
                    title: tr('settings.reminders'),
                    value: s.reminders,
                    onChanged: (v) {
                      s.setReminders(v);
                      v
                          ? Reminders.instance.askOnce().then((_) => Reminders.instance.reschedule())
                          : Reminders.instance.reschedule();
                    },
                  ),
                  if (s.reminders)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(tr('settings.reminderTime'), style: Theme.of(context).textTheme.titleMedium),
                      trailing: Builder(
                        builder: (context) {
                          final m = s.reminderMinutes ?? Reminders.instance.rules.defaultMinutes;
                          final t = TimeOfDay(hour: m ~/ 60, minute: m % 60);
                          return InkButton.paper(
                            label: t.format(context),
                            height: 38,
                            onPressed: () async {
                              final picked = await showWashiTimePicker(
                                context,
                                initial: t,
                                title: tr('settings.reminderTime'),
                                done: tr('common.done'),
                              );
                              if (picked == null) return;
                              s.setReminderMinutes(picked.hour * 60 + picked.minute);
                              Reminders.instance.reschedule();
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(tr('settings.language'), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.start,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final l in supportedLanguages)
                        InkChip(label: tr('lang.$l'), selected: l == currentLanguage, onTap: () => s.setLang(l)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _CloudLine(),
                  Center(
                    child: InkButton.quiet(label: tr('settings.reset'), onPressed: () => _askReset(context)),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// Pregunta antes de borrar la partida; si se confirma, empieza de cero desde
/// la pantalla de título (los ajustes quedan).
Future<void> _askReset(BuildContext context) async {
  final yes = await showWashiDialog<bool>(
    context,
    title: tr('settings.resetAsk'),
    actions: [
      InkButton(label: tr('settings.resetYes'), onPressed: () => Navigator.of(context, rootNavigator: true).pop(true)),
      InkButton.quiet(label: tr('common.cancel'), onPressed: () => Navigator.of(context, rootNavigator: true).pop()),
    ],
  );
  if (yes != true || !context.mounted) return;
  final navigator = Navigator.of(context, rootNavigator: true);
  await Progress.instance.reset(Balance.instance);
  // La partida nueva reemplaza también la de iCloud (y la de otros aparatos).
  await CloudSave.instance.markReset();
  await WeatherService.instance.load(Balance.instance);
  await Reminders.instance.reschedule();
  // Sin transición: el jardín viejo se va enseguida y no convive con el nuevo
  // (comparten las llaves del HUD).
  navigator.pushAndRemoveUntil(
    PageRouteBuilder<void>(
      transitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => const TitleIntro(next: GardenGate(child: GardenScreen())),
    ),
    (_) => false,
  );
}

/// Dónde queda guardado el jardín: iCloud en iOS (si hay sesión) o la copia de
/// seguridad de Google en Android.
class _CloudLine extends StatelessWidget {
  const _CloudLine();

  @override
  Widget build(BuildContext context) {
    final cloud = CloudSave.instance;
    return ValueListenableBuilder(
      valueListenable: cloud.available,
      builder: (context, on, _) {
        final key = Platform.isAndroid ? 'settings.cloudAndroid' : (on ? 'settings.cloud' : 'settings.cloudOff');
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                on || Platform.isAndroid ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                size: 18,
                color: Palette.ink.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  tr(key),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Palette.ink.withValues(alpha: 0.65)),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
