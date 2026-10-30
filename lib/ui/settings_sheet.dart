import 'package:flutter/material.dart';

import 'widgets/washi.dart';

import '../i18n/i18n.dart';
import '../garden/reminders.dart';
import '../settings.dart';
import 'fx/sfx.dart';

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
                      v ? SoundBoard.instance.loop(Ambience.wind, volume: 0.18) : SoundBoard.instance.stopAllLoops();
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
