import 'package:flutter/material.dart';
import '../core/sideline.dart';
import '../utils/team_theme.dart';

/// Resolve the active [TeamColors] extension, falling back to deriving from the
/// color scheme's primary if a subtree somehow lacks the extension.
TeamColors teamColorsOf(BuildContext context) {
  final theme = Theme.of(context);
  return theme.extension<TeamColors>() ??
      TeamColors.fromSeed(theme.colorScheme.primary);
}

/// The dark "hero" shift card: giant mono countdown, an even-rotation pill, a
/// team-colored progress bar, and a muted game/shift footer. Mirrors the
/// Sideline Live Game spec (README → Screens → Hero shift card).
class SidelineHeroShiftCard extends StatelessWidget {
  /// Eyebrow label, e.g. "SHIFT 4 OF 6".
  final String shiftLabel;

  /// Big mono countdown, e.g. "03:12". May be negative ("-0:14") when over.
  final String countdownText;

  /// Caption under the countdown, e.g. "until next shift".
  final String countdownCaption;

  /// Shift-elapsed fraction (0..1) for the progress fill.
  final double progress;

  /// Footer left, e.g. "Game 31:08".
  final String gameClockText;

  /// Footer right, e.g. "Shift 4:48 / 8:00".
  final String shiftClockText;

  /// Whether auto / even rotation is on. Null hides the pill.
  final bool? evenRotation;
  final VoidCallback? onToggleEvenRotation;

  /// Optional top-right control (e.g. the play/pause button). Takes precedence
  /// over the even-rotation pill when both are supplied.
  final Widget? action;

  /// Flashes the countdown red when the shift is over time.
  final bool isOver;

  const SidelineHeroShiftCard({
    super.key,
    required this.shiftLabel,
    required this.countdownText,
    this.countdownCaption = 'until next shift',
    required this.progress,
    required this.gameClockText,
    required this.shiftClockText,
    this.evenRotation,
    this.onToggleEvenRotation,
    this.action,
    this.isOver = false,
  });

  @override
  Widget build(BuildContext context) {
    final team = teamColorsOf(context);
    const onInk = Colors.white;
    final mutedOnInk = onInk.withOpacity(0.62);
    final trackColor = onInk.withOpacity(0.14);

    return Container(
      decoration: BoxDecoration(
        color: SidelineColors.ink,
        borderRadius: BorderRadius.circular(SidelineRadius.card),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF142818).withOpacity(0.20),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        SidelineSpacing.lg,
        SidelineSpacing.md,
        SidelineSpacing.lg,
        SidelineSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  shiftLabel,
                  style: sidelineMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: mutedOnInk,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (action != null)
                action!
              else if (evenRotation != null)
                _EvenRotationPill(
                  active: evenRotation!,
                  onTap: onToggleEvenRotation,
                ),
            ],
          ),
          const SizedBox(height: SidelineSpacing.sm),
          Center(
            child: Text(
              countdownText,
              style: sidelineMono(
                fontSize: 60,
                fontWeight: FontWeight.w700,
                color: isOver ? const Color(0xFFFF6B5A) : onInk,
                letterSpacing: -1.0,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              countdownCaption,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: mutedOnInk,
              ),
            ),
          ),
          const SizedBox(height: SidelineSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(SidelineRadius.pill),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: trackColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOver ? const Color(0xFFFF6B5A) : team.team,
              ),
            ),
          ),
          const SizedBox(height: SidelineSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                gameClockText,
                style: sidelineMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: mutedOnInk,
                ),
              ),
              Text(
                shiftClockText,
                style: sidelineMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: mutedOnInk,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EvenRotationPill extends StatelessWidget {
  final bool active;
  final VoidCallback? onTap;
  const _EvenRotationPill({required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    final team = teamColorsOf(context);
    final bg = active ? team.team.withOpacity(0.22) : Colors.white.withOpacity(0.10);
    final fg = active ? Colors.white : Colors.white.withOpacity(0.62);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SidelineRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(SidelineRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(active ? Icons.balance : Icons.tune, size: 14, color: fg),
              const SizedBox(width: 6),
              Text(
                'Even rotation',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline "shift ending soon" banner: whistle-soft background, whistle border,
/// a pulsing amber dot. Tie its visibility to the shift-alarm threshold.
class SidelineAlertBanner extends StatefulWidget {
  final String message;
  final VoidCallback? onDismiss;
  const SidelineAlertBanner({super.key, required this.message, this.onDismiss});

  @override
  State<SidelineAlertBanner> createState() => _SidelineAlertBannerState();
}

class _SidelineAlertBannerState extends State<SidelineAlertBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SidelineSpacing.md,
        vertical: SidelineSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: SidelineColors.whistleSoft,
        borderRadius: BorderRadius.circular(SidelineRadius.row),
        border: Border.all(color: SidelineColors.whistle),
      ),
      child: Row(
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.35).animate(_pulse),
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: SidelineColors.whistle,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: SidelineSpacing.sm),
          Expanded(
            child: Text(
              widget.message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: SidelineColors.whistleText,
              ),
            ),
          ),
          if (widget.onDismiss != null)
            IconButton(
              onPressed: widget.onDismiss,
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.close,
                size: 18,
                color: SidelineColors.whistleText,
              ),
            ),
        ],
      ),
    );
  }
}

/// A single on-the-pitch player row: number badge + name + playtime bar +
/// position chip + minutes. Colors derive from the active [TeamColors].
class SidelinePlayerShiftRow extends StatelessWidget {
  final String number;
  final String name;
  final String positionLabel;
  final bool isGoalkeeper;
  final int minutesPlayed;

  /// Denominator for the playtime bar (e.g. max minutes across the squad).
  final int totalMinutes;
  final VoidCallback? onTap;
  final Widget? trailing;

  const SidelinePlayerShiftRow({
    super.key,
    required this.number,
    required this.name,
    required this.positionLabel,
    required this.minutesPlayed,
    required this.totalMinutes,
    this.isGoalkeeper = false,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final team = teamColorsOf(context);
    final fraction = totalMinutes <= 0
        ? 0.0
        : (minutesPlayed / totalMinutes).clamp(0.0, 1.0);

    return Material(
      color: SidelineColors.surface,
      borderRadius: BorderRadius.circular(SidelineRadius.row),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SidelineRadius.row),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SidelineRadius.row),
            border: Border.all(color: SidelineColors.hairline),
          ),
          child: Row(
            children: [
              _NumberBadge(number: number),
              const SizedBox(width: SidelineSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: SidelineColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(SidelineRadius.pill),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 5,
                        backgroundColor: SidelineColors.hairline,
                        valueColor: AlwaysStoppedAnimation<Color>(team.team),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: SidelineSpacing.sm),
              SidelinePositionChip(
                label: positionLabel,
                isGoalkeeper: isGoalkeeper,
              ),
              const SizedBox(width: SidelineSpacing.sm),
              SizedBox(
                width: 40,
                child: Text(
                  '$minutesPlayed',
                  textAlign: TextAlign.right,
                  style: sidelineMono(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: SidelineColors.ink,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  final String number;
  const _NumberBadge({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SidelineColors.ink,
        borderRadius: BorderRadius.circular(SidelineRadius.chip),
      ),
      child: Text(
        number,
        style: sidelineMono(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Position chip: GK is an ink pill; outfield chips are team-soft bg with
/// team-strong text.
class SidelinePositionChip extends StatelessWidget {
  final String label;
  final bool isGoalkeeper;
  const SidelinePositionChip({
    super.key,
    required this.label,
    this.isGoalkeeper = false,
  });

  @override
  Widget build(BuildContext context) {
    final team = teamColorsOf(context);
    final bg = isGoalkeeper ? SidelineColors.ink : team.soft;
    final fg = isGoalkeeper ? Colors.white : team.strong;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(SidelineRadius.chip),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

/// "Next on" pill chip: number circle + name + minutes. The lowest-minute
/// players are [highlight]ed (whistle-soft) to nudge fair rotation.
class SidelineNextOnChip extends StatelessWidget {
  final String number;
  final String name;
  final int minutes;
  final bool highlight;
  final VoidCallback? onTap;

  const SidelineNextOnChip({
    super.key,
    required this.number,
    required this.name,
    required this.minutes,
    this.highlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = highlight ? SidelineColors.whistleSoft : SidelineColors.surface;
    final border = highlight ? SidelineColors.whistle : SidelineColors.hairline;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SidelineRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(SidelineRadius.pill),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: SidelineColors.ink,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  number,
                  style: sidelineMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: SidelineColors.ink,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${minutes}m',
                style: sidelineMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: highlight
                      ? SidelineColors.whistleText
                      : SidelineColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
