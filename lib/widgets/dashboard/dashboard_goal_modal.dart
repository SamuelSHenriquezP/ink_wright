import 'package:flutter/material.dart';
import '../../controllers/editor_controller.dart';
import '../../theme/app_theme.dart';

class DashboardGoalModal {
  static void show(BuildContext context, EditorController controller, bool isDark) {
    final currentGoal = controller.writerStats.dailyGoalWords;
    int selectedWords = currentGoal;
    final customCtrl = TextEditingController(text: currentGoal.toString());
    final presets = [500, 1000, 1500, 2000, 3000];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bgCard = isDark ? const Color(0xFF1E1E22) : Colors.white;
            final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
            final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
            final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: AppTheme.getSoftShadow(isDark),
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: textSecondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.flag_rounded, color: textPrimary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Meta Diaria de Escritura',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Ajusta tu objetivo diario de palabras',
                                style: TextStyle(fontSize: 12, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'PRESETS RÁPIDOS (PALABRAS)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presets.map((p) {
                        final isSelected = selectedWords == p;
                        return ChoiceChip(
                          label: Text(
                            '$p',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? (isDark ? Colors.black : Colors.white) : textPrimary,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: isDark ? Colors.white : Colors.black,
                          backgroundColor: isDark ? const Color(0xFF252525) : const Color(0xFFF4F3EF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: isSelected ? Colors.transparent : borderSubtle),
                          ),
                          showCheckmark: false,
                          onSelected: (sel) {
                            if (sel) {
                              setModalState(() {
                                selectedWords = p;
                                customCtrl.text = p.toString();
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'O INGRESA UN VALOR PERSONALIZADO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: customCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'ej: 1200',
                        suffixText: 'palabras / día',
                        suffixStyle: TextStyle(color: textSecondary, fontSize: 13),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF18181A) : const Color(0xFFF9F9FB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: borderSubtle),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: borderSubtle),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: textPrimary, width: 1.5),
                        ),
                      ),
                      onChanged: (val) {
                        final parsed = int.tryParse(val.trim());
                        if (parsed != null && parsed > 0) {
                          setModalState(() {
                            selectedWords = parsed;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : Colors.black,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text(
                          'Guardar Meta Diaria',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        onPressed: () {
                          final parsed = int.tryParse(customCtrl.text.trim()) ?? selectedWords;
                          if (parsed > 0) {
                            controller.updateDailyGoal(parsed);
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Meta diaria establecida en $parsed palabras'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

