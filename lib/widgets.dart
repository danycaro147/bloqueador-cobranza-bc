import 'package:flutter/material.dart';

import 'bridge.dart';
import 'theme.dart';

/// Ilustración: escudo con auricular tachado (misma idea que el ícono).
class ShieldArt extends StatelessWidget {
  final double size;
  final IconData icon;
  final bool ok;
  const ShieldArt(
      {super.key,
      this.size = 120,
      this.icon = Icons.phone_disabled_rounded,
      this.ok = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: ok
              ? [const Color(0xFF2FB57A), const Color(0xFF167A4B)]
              : [AppColors.brand, AppColors.brandDeep],
        ),
        boxShadow: [
          BoxShadow(
              color: (ok ? AppColors.success : AppColors.brand).withAlpha(60),
              blurRadius: 30,
              offset: const Offset(0, 12)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.shield_rounded, size: size * .62, color: Colors.white),
          Padding(
            padding: EdgeInsets.only(bottom: size * .03),
            child: Icon(icon,
                size: size * .26,
                color: ok ? const Color(0xFF167A4B) : AppColors.brandDeep),
          ),
        ],
      ),
    );
  }
}

/// Selector de nivel de protección (tarjetas tipo radio).
class LevelSelector extends StatelessWidget {
  final ProtectionLevel selected;
  final ValueChanged<ProtectionLevel> onChanged;

  const LevelSelector(
      {super.key, required this.selected, required this.onChanged});

  static const _desc = {
    ProtectionLevel.recomendado:
        'Bloquea desconocidos y ocultos. Si un número insiste 2 veces en 3 '
            'minutos, lo deja pasar por si es urgente.',
    ProtectionLevel.estricto:
        'Solo entran tus contactos y tu lista de permitidos. Sin excepciones.',
    ProtectionLevel.soloLista:
        'Solo bloquea los números que tú agregues y los falsificados.',
  };

  static const _icons = {
    ProtectionLevel.recomendado: Icons.verified_user_rounded,
    ProtectionLevel.estricto: Icons.lock_rounded,
    ProtectionLevel.soloLista: Icons.playlist_remove_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      children: [
        for (final l in _desc.keys)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: l == selected
                  ? cs.primaryContainer.withAlpha(140)
                  : Theme.of(context).cardTheme.color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                    color: l == selected
                        ? cs.primary
                        : cs.outlineVariant.withAlpha(110),
                    width: l == selected ? 2 : 1),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onChanged(l),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(_icons[l],
                          color: l == selected ? cs.primary : cs.onSurfaceVariant),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(levelName(l),
                                    style: tt.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700)),
                                if (l == ProtectionLevel.recomendado)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: cs.primary,
                                        borderRadius: BorderRadius.circular(20)),
                                    child: Text('Sugerido',
                                        style: tt.labelSmall?.copyWith(
                                            color: cs.onPrimary,
                                            fontWeight: FontWeight.w700)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(_desc[l]!,
                                style: tt.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant, height: 1.35)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        l == selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: l == selected ? cs.primary : cs.outline,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (selected == ProtectionLevel.personalizado)
          const InfoBox(
              icon: Icons.tune_rounded,
              text: 'Estás usando una combinación personalizada. Elige un nivel '
                  'para volver a los ajustes sugeridos.'),
      ],
    );
  }
}
