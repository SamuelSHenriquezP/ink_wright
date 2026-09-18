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
          height: MediaQuery.of(context).size.height * 0.88,
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
            border: Border.all(color: borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('🖋️', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Guía Integral — Ink & Wright',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Manual completo de herramientas, análisis y narrativa',
                          style: TextStyle(fontSize: 11.5, color: textSecondary),
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
              const SizedBox(height: 12),

              // Tutorial Sections Scroll
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SECCIÓN 1: EL EDITOR & ESTILO
                      _buildSectionLabel('1. EL EDITOR & ESTILO DE PROSA', textSecondary),
                      const SizedBox(height: 8),
                      _buildTutorialItem(
                        icon: Icons.edit_note_rounded,
                        title: 'Editor con Markdown en Vivo & Botón [MD]',
                        description:
                            'Escribe con libertad y sin distracciones. Tus encabezados (#), negritas (**texto**), cursivas (*texto*), tachados (~~texto~~), citas (>) y listas (- [ ]) se renderizan en tiempo real. Pulsa la píldora [MD] en la barra superior para alternar entre ver los símbolos markdown o un lienzo limpio.',
                        badge: 'Básico',
                        isDark: isDark,
                        borderSubtle: borderSubtle,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 10),
                      _buildTutorialItem(
                        icon: Icons.auto_awesome_rounded,
                        title: 'Inspector de Prosa y Ritmo Narrativo',
                        description:
                            'Ubicado en el botón [✨ Inspector] junto a las métricas del capítulo. Analiza en tiempo real:\n• Legibilidad Fernández-Huerta (0-100) y promedio de palabras por frase.\n• Adverbios en -mente para sustituirlos por verbos más vivaces.\n• Oraciones densas (>32 palabras) para dosificar la cadencia.\n• Ecos acústicos (palabras repetidas en un mismo párrafo).\n• Muletillas de relleno (realmente, prácticamente, simplemente...).\n• Clichés literarios (en un abrir y cerrar de ojos, frío sepulcral...).\n• Voz pasiva débil para favorecer construcciones activas dinámicas.\n• Párrafos densos (>100 palabras) para oxigenar la lectura en pantalla.',
                        badge: 'Destacado',
                        isDark: isDark,
                        borderSubtle: borderSubtle,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 10),
                      _buildTutorialItem(
                        icon: Icons.keyboard_outlined,
                        title: 'Modo Máquina de Escribir & Tipografía',
                        description:
                            'Activa el modo máquina de escribir desde el menú de opciones [ ⋮ ] para mantener siempre centrada verticalmente la línea que estás redactando. En "Tipografía y Diseño" puedes elegir entre fuentes de corte editorial (Lora, Merriweather, Playfair Display o JetBrains Mono), modificar el tamaño de letra, interlineado y margen horizontal.',
                        badge: 'Ergonomía',
                        isDark: isDark,
                        borderSubtle: borderSubtle,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),

                      const SizedBox(height: 18),
                      // SECCIÓN 2: HERRAMIENTAS EDITORIALES
                      _buildSectionLabel('2. REVISIÓN, VERSIONES & BÚSQUEDA', textSecondary),
                      const SizedBox(height: 8),
                      _buildTutorialItem(
                        icon: Icons.history_rounded,
                        title: 'Historial de Versiones e Instantáneas (Snapshots)',
                        description:
                            'Disponible en el menú de tres puntos [ ⋮ ]. Guarda puntos de restauración de tu capítulo con fecha, hora y conteo de palabras. Te permite probar giros arriesgados y restaurar borradores anteriores en cualquier instante con un solo toque.',
                        badge: 'Seguridad',
                        isDark: isDark,
                        borderSubtle: borderSubtle,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 10),
                      _buildTutorialItem(
                        icon: Icons.rate_review_outlined,
                        title: 'Notas de Revisión y Comentarios Marginales',
                        description:
                            'Selecciona cualquier frase o párrafo en el editor y abre "Notas de Revisión" en el menú [ ⋮ ]. Puedes dejarte comentarios editoriales, dudas de continuidad o recordatorios asociados a ese fragmento exacto sin ensuciar el texto de tu novela. Márcalas como resueltas conforme avances.',
                        badge: 'Edición',
                        isDark: isDark,
                        borderSubtle: borderSubtle,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 10),
                      _buildTutorialItem(
                        icon: Icons.find_replace_rounded,
                        title: 'Buscar y Reemplazar (Capítulo o Todo el Libro)',
                        description:
                            'Ábrelo con Ctrl+F o desde el menú de opciones [ ⋮ ]. Cuenta con sensibilidad a mayúsculas/minúsculas [Aa] y navegación entre coincidencias. Permite reemplazar en el capítulo activo o realizar reemplazos masivos en todos los capítulos del libro (ideal al cambiar el nombre de un personaje o lugar en toda la obra).',
                        badge: 'Herramienta',
                        isDark: isDark,
                        borderSubtle: borderSubtle,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 10),
                      _buildTutorialItem(
                        icon: Icons.auto_stories_outlined,
                        title: 'Lector de Manuscrito Completo (En Cascada)',
                        description:
                            'Toca el icono del libro abierto en la barra superior. Te permite leer tu obra entera en flujo continuo, sin botones ni distracciones de edición, con estimación de minutos de lectura y barra de progreso superior para evaluar la inmersión del lector.',
                        badge: 'Lectura',
                        isDark: isDark,
                        borderSubtle: borderSubtle,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),

                      const SizedBox(height: 18),
                      // SECCIÓN 3: ESTRUCTURA, PERSONAJES & TRAMA
                      _buildSectionLabel('3. ESTRUCTURA, PERSONAJES & TRAMA', textSecondary),
                      const SizedBox(height: 8),
                      _buildTutorialItem(
                        icon: Icons.groups_rounded,
                        title: 'Fichas de Personajes y Red de Relaciones',
                        description:
                            'En la pestaña "Personajes" puedes profundizar en la psicología de cada protagonista: deseo consciente, necesidad inconsciente, herida del pasado y notas físicas. En la vista "Relaciones" verás un mapa interactivo de vínculos (aliados, rivales, mentores, romances, familia) con medidor de intensidad.',
                        badge: 'Narrativa',
                        isDark: isDark,
                        borderSubtle: borderSubtle,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 10),
                      _buildTutorialItem(
                        icon: Icons.hub_outlined,
                        title: 'Mapa Mental y Línea de Tiempo (Timeline)',
                        description:
                            'Cada libro tiene su lienzo infinito exclusivo para trazar tramas y subtramas. Conecta nodos con flechas de causa y efecto. Con el botón superior de Línea de Tiempo, conmuta instantáneamente a una vista cronológica organizada en 5 actos clásicos (Planteamiento, Nudo, Punto Medio, Clímax y Resolución) donde puedes arrastrar escenas.',
                        badge: 'Estructura',
                        isDark: isDark,
                        borderSubtle: borderSubtle,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 10),
                      _buildTutorialItem(
                        icon: Icons.dashboard_customize_outlined,
                        title: 'Tablón de Fichas (Corkboard)',
                        description:
                            'Visualiza tu manuscrito en cuadrícula panorámica de tarjetas de sinopsis. Cada tarjeta muestra el título, sinopsis argumental, estado y conteo de palabras del capítulo, permitiéndote comprobar el ritmo de la historia de un solo vistazo.',
                        badge: 'Planificación',
                        isDark: isDark,
                        borderSubtle: borderSubtle,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),

                      const SizedBox(height: 18),
                      // SECCIÓN 4: ENFOQUE, MUNDO & RESPALDOS
                      _buildSectionLabel('4. ENFOQUE, MUNDO & RESPALDOS', textSecondary),
                      const SizedBox(height: 8),
                      _buildTutorialItem(
                        icon: Icons.timer_outlined,
                        title: 'Sprints de Escritura, Sonidos y Concentración',
                        description:
                            'Activa el modo pantalla completa para silenciar interfaces. Inicia sprints cronometrados de escritura (5, 15, 25 min) con objetivos de palabras y consulta tu ritmo (palabras/minuto) en el historial de sprints. Acompaña tus sesiones con sonidos ambientales relajantes (lluvia, fuego, café).',
                        badge: 'Productividad',
                        isDark: isDark,
                        borderSubtle: borderSubtle,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 10),
                      _buildTutorialItem(
                        icon: Icons.menu_book_rounded,
                        title: 'Códex de Worldbuilding & Musa Creativa',
                        description:
                            'El Códex es la enciclopedia de tu universo: registra facciones, regiones geográficas, sistemas de magia y artefactos clave. Si sufres bloqueo de escritor, la Musa Creativa te ofrece detonantes, preguntas dramáticas y giros argumentales contextuales.',
                        badge: 'Worldbuilding',
                        isDark: isDark,
                        borderSubtle: borderSubtle,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 10),
                      _buildTutorialItem(
                        icon: Icons.backup_table_rounded,
                        title: 'Exportación Editorial & Respaldos .inkwright',
                        description:
                            'Exporta tu novela completa a formatos listos para lectura o imprenta: PDF maquetado, EPUB para lectores digitales, texto plano TXT o Markdown compilado. Además, puedes generar o restaurar respaldos completos en formato .inkwright para no perder jamás tu trabajo al cambiar de dispositivo.',
                        badge: 'Exportación',
                        isDark: isDark,
                        borderSubtle: borderSubtle,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Botón para ir al libro tutorial
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.auto_stories_rounded, size: 20),
                  label: const Text(
                    'Abrir el Manual del Escritor en el Editor',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
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

  static Widget _buildSectionLabel(String text, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: textSecondary.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  static Widget _buildTutorialItem({
    required IconData icon,
    required String title,
    required String description,
    required String badge,
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11.8,
                    color: textSecondary,
                    height: 1.48,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
