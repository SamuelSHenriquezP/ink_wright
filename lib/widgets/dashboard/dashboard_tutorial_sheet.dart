import 'package:flutter/material.dart';
import '../../controllers/editor_controller.dart';
import '../../screens/zen_editor_screen.dart';
import '../../theme/app_theme.dart';

class DashboardTutorialSheet {
  static void show(BuildContext context, bool isDark, EditorController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
        final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
        final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
        final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

        return Container(
          height: MediaQuery.of(context).size.height * 0.82,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
            border: Border.all(color: borderSubtle),
          ),
          child: Column(
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
                  const Text('🖋️', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Guía de Inicio — Ink & Wright',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Tu estudio minimalista de narrativa y planificación',
                          style: TextStyle(fontSize: 11, color: textSecondary),
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
              const SizedBox(height: 12),
              Divider(height: 1, color: borderSubtle),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTutorialItem(
                        icon: Icons.edit_note_rounded,
                        title: '1. Editor con Markdown en Vivo',
                        description:
                            'Escribe con total fluidez. Tus títulos (#), negritas (**texto**), cursivas (*texto*), citas (>), rayas de diálogo (—) y tareas (- [ ]) se renderizan en tiempo real mientras tecleas.',
                        isDark: isDark,
                        borderSubtle: borderSubtle,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 12),
                      _buildTutorialItem(
                        icon: Icons.person_search_rounded,
                        title: '2. Fichas de Personajes Narrativos',
                        description:
                            'Cada libro cuenta con su propia sección de Personajes. Define su psicología, motivaciones, debilidades y redacta su biografía escrita para insertarla en tu manuscrito.',
                        isDark: isDark,
                        borderSubtle: borderSubtle,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 12),
                      _buildTutorialItem(
                        icon: Icons.hub_outlined,
                        title: '3. Mapa Mental Individual por Libro',
                        description:
                            'Un lienzo visual exclusivo para cada proyecto. Conecta causas y consecuencias, arrastra ideas por el espacio infinito y auto-organiza tu trama en columnas por actos narrativos.',
                        isDark: isDark,
                        borderSubtle: borderSubtle,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 12),
                      _buildTutorialItem(
                        icon: Icons.fullscreen_rounded,
                        title: '4. Modo Pantalla Completa & Concentración',
                        description:
                            'Toca el botón de pantalla completa para ocultar barras y controles. Activa paisajes sonoros (lluvia, fuego, café) y sprints cronometrados para mantener tu ritmo.',
                        isDark: isDark,
                        borderSubtle: borderSubtle,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.auto_stories_rounded, size: 20),
                  label: const Text(
                    'Abrir el Manual del Escritor',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  onPressed: () {
                    final tutBook = controller.allBooks.firstWhere(
                      (b) => b.id == 'b_tutorial',
                      orElse: () => controller.allBooks.first,
                    );
                    controller.selectBook(tutBook);
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ZenEditorScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildTutorialItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
    required Color borderSubtle,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: textSecondary, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

