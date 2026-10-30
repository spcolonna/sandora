import 'package:flutter/material.dart';

import 'widgets/washi.dart';

import '../i18n/i18n.dart';
import '../garden/reminders.dart';
import '../settings.dart';
import 'fx/sfx.dart';
import 'theme/palette.dart';

Future<void> showSettingsSheet(BuildContext context) {
  return showWashiSheet(
    context,
    builder: (context) => ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final s = AppSettings.instance;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tr('settings.title'), style: Theme.of(context).textTheme.titleLarge),
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
                        return TextButton(
                          onPressed: () async {
                            final picked = await showTimePicker(context: context, initialTime: t);
                            if (picked == null) return;
                            s.setReminderMinutes(picked.hour * 60 + picked.minute);
                            Reminders.instance.reschedule();
                          },
                          child: Text(
                            t.format(context),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        );
                      },
                    ),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr('settings.language'), style: Theme.of(context).textTheme.titleMedium),
                  trailing: DropdownButton<String>(
                    value: currentLanguage,
                    underline: const SizedBox(),
                    dropdownColor: Palette.sandLight,
                    borderRadius: BorderRadius.circular(16),
                    items: [for (final l in supportedLanguages) DropdownMenuItem(value: l, child: Text(tr('lang.$l')))],
                    onChanged: (v) => s.setLang(v!),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    ),
  );
}
