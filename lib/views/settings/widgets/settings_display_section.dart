import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/display_settings.dart';

class SettingsDisplaySection extends StatelessWidget {
  const SettingsDisplaySection({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DisplaySettings>();
    final isAuto = settings.mode == BrightnessMode.automatic;
    final brightness = settings.manualBrightness;
    final percent = (brightness * 100).round();
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SegmentedButton<BrightnessMode>(
            segments: const [
              ButtonSegment(
                value: BrightnessMode.automatic,
                label: Text('Авто'),
                icon: Icon(Icons.brightness_high),
              ),
              ButtonSegment(
                value: BrightnessMode.manual,
                label: Text('Вручную'),
                icon: Icon(Icons.tune),
              ),
            ],
            selected: {settings.mode},
            onSelectionChanged: (s) => settings.setMode(s.first),
          ),
        ),
        ListTile(
          leading: Icon(Icons.brightness_6, color: scheme.primary),
          title: Text(
            isAuto ? 'Яркость 100% при показе кода' : 'Ручная яркость кода',
          ),
          subtitle: isAuto
              ? const Text(
                  'Экран загорается на максимум при открытии штрихкода на весь экран',
                )
              : Text('Применяется при открытии штрихкода • $percent%'),
        ),
        if (!isAuto)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(
                  Icons.brightness_low,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                Expanded(
                  child: Slider(
                    value: brightness,
                    min: DisplaySettings.minBrightness,
                    max: 1.0,
                    divisions: 14,
                    label: '$percent%',
                    onChanged: (v) => settings.setManualBrightness(v),
                  ),
                ),
                Icon(
                  Icons.brightness_high,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
      ],
    );
  }
}
