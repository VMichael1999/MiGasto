import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/mg_colors.dart';
import '../../presentation/providers.dart';
import '../profile.dart';

/// Botón de perfil de las cabeceras: muestra las iniciales del usuario (o un
/// ícono si aún no puso su nombre) y abre el Perfil encima de la pantalla actual.
class ProfileAvatarButton extends ConsumerWidget {
  const ProfileAvatarButton({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initials = initialsOf(ref.watch(profileNameProvider));
    return Semantics(
      button: true,
      label: 'Perfil',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.push('/settings'),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MgColors.accSoft,
              border: Border.all(color: MgColors.accLine),
            ),
            child: Center(
              child: initials.isEmpty
                  ? Icon(Icons.person_outline_rounded, size: size * 0.5, color: MgColors.acc2)
                  : Text(
                      initials,
                      style: TextStyle(
                        fontSize: size * 0.34,
                        fontWeight: FontWeight.w700,
                        color: MgColors.acc2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
