import 'package:flutter/material.dart';

import '../i18n/i18n.dart';
import '../garden/reminders.dart';
import '../settings.dart';
import 'fx/sfx.dart';

Future<void> showSettingsSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) => ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final s = AppSettings.instance;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tr('settings.title'), style: Theme.of(context).textTheme.titleLarge),
              SwitchListTile(title: Text(tr('settings.sound')), value: s.sound, onChanged: s.setSound),
              SwitchListTile(
                title: Text(tr('settings.music')),
                value: s.music,
                onChanged: (v) {
                  s.setMusic(v);
                  v ? SoundBoard.instance.loop(Ambience.wind, volume: 0.18) : SoundBoard.instance.stopAllLoops();
                },
              ),
              SwitchListTile(title: Text(tr('settings.haptics')), value: s.haptics, onChanged: s.setHaptics),
              SwitchListTile(
                title: Text(tr('settings.reminders')),
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
                  title: Text(tr('settings.reminderTime')),
                  trailing: Builder(
                    builder: (context) {
                      final m = s.reminderMinutes ?? Reminders.instance.rules.defaultMinutes;
                      final t = TimeOfDay(hour: m ~/ 60, minute: m % 60);
                      return TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: t);
                          if (picked == null) return;
                          s.setReminderMinutes(picked.hour * 60 + picked.minute);
                          Reminders.instance.reschedule();
                        },
                        child: Text(t.format(context)),
                      );
                    },
                  ),
                ),
              ListTile(
                title: Text(tr('settings.language')),
                trailing: DropdownButton<String>(
                  value: currentLanguage,
                  underline: const SizedBox(),
                  items: [for (final l in supportedLanguages) DropdownMenuItem(value: l, child: Text(tr('lang.$l')))],
                  onChanged: (v) => s.setLang(v!),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    ),
  );
}
