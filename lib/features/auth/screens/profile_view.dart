import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/vibe_constants.dart';
import '../providers/auth_provider.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: VibeColors.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            CircleAvatar(
              radius: 48,
              backgroundColor: VibeColors.mint.withValues(alpha: 0.2),
              child: const Icon(Icons.person_rounded,
                  size: 52, color: VibeColors.navy),
            ),
            const SizedBox(height: 16),
            Text(
              user?.displayName ??
                  user?.email.split('@').firstOrNull ??
                  'Invitado',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: VibeColors.navy,
              ),
            ),
            if (user?.email != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  user!.email,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: VibeColors.mint.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Miembro',
                style: TextStyle(
                    color: VibeColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 32),
            const Spacer(),
            if (user != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await context.read<AuthProvider>().signOut();
                      // AuthGate resuelve la navegación al login automáticamente.
                    },
                    icon: const Icon(Icons.logout_rounded, color: Colors.red),
                    label: const Text('Cerrar Sesión',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
