import 'package:flutter/material.dart';

import '../i18n/i18n.dart';
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
