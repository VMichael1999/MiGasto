import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../providers.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              // Wallet Logo Image representation
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.2), width: 2),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.account_balance_wallet,
                    size: 48,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // App Name & Slogan
              Center(
                child: Text(
                  'MisGastos',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Detecta. Categoriza. Controla.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Detecta automáticamente tus pagos de Yape, Plin o Google Pay y lleva el control de tus gastos sin registrarlos manualmente.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(flex: 2),

              // Features List
              _buildFeatureItem(
                context,
                Icons.notifications_active_outlined,
                'Detección automática en tiempo real',
              ),
              const SizedBox(height: 14),
              _buildFeatureItem(
                context,
                Icons.local_offer_outlined,
                'Categorización inteligente',
              ),
              const SizedBox(height: 14),
              _buildFeatureItem(
                context,
                Icons.bar_chart_outlined,
                'Estadísticas claras y poderosas',
              ),
              const SizedBox(height: 14),
              _buildFeatureItem(
                context,
                Icons.verified_user_outlined,
                '100% seguro y privado',
              ),

              const Spacer(flex: 3),

              // Material You Badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1922),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2E2B3B)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.palette_outlined, color: Colors.greenAccent, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Diseñado con Material You',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[300],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Confirm/Start Button
              ElevatedButton(
                onPressed: () {
                  final prefs = ref.read(sharedPreferencesProvider);
                  prefs.setBool('onboarding_complete', true);
                  context.go('/dashboard');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Comenzar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.neonGreen, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
