import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Password strength model — calculated from the raw password string.
class PasswordStrength {
  final int score;       // 0-5
  final String label;    // 'Too short' | 'Weak' | 'Fair' | 'Strong' | 'Very strong'
  final Color color;
  final List<PasswordRequirement> requirements;

  const PasswordStrength._({
    required this.score,
    required this.label,
    required this.color,
    required this.requirements,
  });

  factory PasswordStrength.of(String password) {
    final reqs = [
      PasswordRequirement('At least 8 characters', password.length >= 8),
      PasswordRequirement('Uppercase letter (A-Z)',
          password.contains(RegExp(r'[A-Z]'))),
      PasswordRequirement('Lowercase letter (a-z)',
          password.contains(RegExp(r'[a-z]'))),
      PasswordRequirement('Number (0-9)',
          password.contains(RegExp(r'[0-9]'))),
      PasswordRequirement('Special character (!@#\$...)',
          password.contains(RegExp(
              r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\;' "'" r'`~]'))),
    ];

    final score = reqs.where((r) => r.met).length;

    if (password.isEmpty) {
      return PasswordStrength._(
          score: 0, label: '', color: Colors.transparent, requirements: reqs);
    }

    final (label, color) = switch (score) {
      0 || 1 => ('Weak',        const Color(0xFFE53935)),
      2       => ('Fair',        const Color(0xFFFF9800)),
      3       => ('Good',        const Color(0xFFFFD600)),
      4       => ('Strong',      const Color(0xFF43A047)),
      _       => ('Very strong', const Color(0xFF1B5E20)),
    };

    return PasswordStrength._(
        score: score, label: label, color: color, requirements: reqs);
  }

  /// True when the password is Strong or Very Strong — meets at least
  /// 4 of the 5 requirements. Anything below this is rejected at submit.
  bool get isAcceptable => score >= 4;
}

class PasswordRequirement {
  final String text;
  final bool met;
  const PasswordRequirement(this.text, this.met);
}

/// Widget that shows the strength bar + requirement checklist.
/// Drop it directly below the password TextFormField.
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final strength = PasswordStrength.of(password);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Strength bar ─────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: strength.score / 5,
                    minHeight: 6,
                    backgroundColor: AppColors.divider,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(strength.color),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                strength.label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: strength.color),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Requirements checklist ────────────────────────────────
          ...strength.requirements.map(
            (req) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Icon(
                    req.met
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 15,
                    color: req.met
                        ? AppColors.success
                        : AppColors.textHint,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    req.text,
                    style: TextStyle(
                        fontSize: 12,
                        color: req.met
                            ? AppColors.textPrimary
                            : AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
