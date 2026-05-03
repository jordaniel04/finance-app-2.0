import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/app_theme.dart';
import '../blocs/ai_tip_cubit.dart';

/// Banner dismissible para el Dashboard — aparece una vez por día.
class AiTipBanner extends StatelessWidget {
  const AiTipBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AiTipCubit, AiTipState>(
      builder: (context, state) {
        if (state is AiTipLoading) return const _TipSkeleton();
        if (state is! AiTipLoaded || state.dismissed) return const SizedBox.shrink();
        return _TipCard(tip: state.tip, dismissible: true);
      },
    );
  }
}

/// Tarjeta permanente para Reportes — sin botón cerrar.
class AiTipCard extends StatelessWidget {
  const AiTipCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AiTipCubit, AiTipState>(
      builder: (context, state) {
        if (state is AiTipLoading) return const _TipSkeleton();
        if (state is! AiTipLoaded) return const SizedBox.shrink();
        return _TipCard(tip: state.tip, dismissible: false);
      },
    );
  }
}

class _TipCard extends StatelessWidget {
  final String tip;
  final bool dismissible;
  const _TipCard({required this.tip, required this.dismissible});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, color: c.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          if (dismissible) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => context.read<AiTipCubit>().dismiss(),
              child: Icon(Icons.close_rounded, color: c.iconMuted, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}

class _TipSkeleton extends StatelessWidget {
  const _TipSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.surfaceBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: c.iconMuted, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 10, decoration: BoxDecoration(color: c.divider, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 6),
                Container(height: 10, width: 200, decoration: BoxDecoration(color: c.divider, borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
