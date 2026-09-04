import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/editor_controller.dart';
import '../models/idea_snippet_model.dart';

class MuseAssistantSheet extends StatefulWidget {
  final bool isDark;

  const MuseAssistantSheet({
    super.key,
    required this.isDark,
  });

  @override
  State<MuseAssistantSheet> createState() => _MuseAssistantSheetState();
}

class _MuseAssistantSheetState extends State<MuseAssistantSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Random _random = Random();
  String _generatedOutput = '';
  String _activePromptType = 'Giro de Trama';

  // Spanish sample prompt engine datasets
  final List<String> _plotTwists = [
    "La brújula de plata no apunta al norte ni a la abadía; sigue la ubicación de la sombra perdida del protagonista.",
    "El diario de viaje no fue escrito por el cartógrafo, sino enviado por la orden para borrar sus propios recuerdos.",
    "La niebla sobre el valle solo avanza cuando alguien pronuncia una mentira a menos de tres kilómetros del santuario.",
    "Los mapas trazados hace treinta años no registraban el terreno, sino que profetizaban el colapso del castillo.",
    "El reloj del campanario no marca las horas; repica únicamente cuando se altera un capítulo de la historia del pueblo.",
  ];

  final List<String> _sensoryDetails = [
    "Olor a musgo húmedo, humo de vela de sebo rancia y el tenue toque metálico del latón viejo tras la lluvia.",
    "Un ráfaga helada recorrió el suelo de madera, impregnada de resina de pino y pergamino olvidado.",
    "El silencio era denso, interrumpido únicamente por el tic-tac sincronizado de dos relojes de bolsillo desfasados por 12 segundos.",
    "La luz de la luna atravesaba los vitrales, proyectando sombras geométricas azabache y carmesí sobre el empedrado.",
  ];

  final List<String> _dialogueSparks = [
    "«Si dejamos de escribir la historia ahora, Silas, la historia comenzará a escribirnos a nosotros.»",
    "«Un secreto enterrado en tierra húmeda no se pudre; echa raíces.»",
    "«No confíes en un mapa dibujado por alguien que sobrevivió a la noche en la abadía.»",
    "«La montaña recuerda cada palabra que le susurraste en la oscuridad.»",
  ];

  final List<String> _characterFlaws = [
    "Obsesión inflexible por la precisión cartográfica, incluso bajo peligro inminente.",
    "Se niega rotundamente a leer cartas escritas después del atardecer por temor supersticioso.",
    "Esconde una vieja llave de latón dentro de la encuadernación de cada libro que toca.",
    "Escucha campanadas distantes cada vez que debe tomar una decisión decisiva.",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _generatePrompt(0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _generatePrompt(int tabIndex) {
    setState(() {
      switch (tabIndex) {
        case 0:
          _activePromptType = 'Giro de Trama';
          _generatedOutput = _plotTwists[_random.nextInt(_plotTwists.length)];
          break;
        case 1:
          _activePromptType = 'Detalle Sensorial';
          _generatedOutput = _sensoryDetails[_random.nextInt(_sensoryDetails.length)];
          break;
        case 2:
          _activePromptType = 'Diálogo';
          _generatedOutput = _dialogueSparks[_random.nextInt(_dialogueSparks.length)];
          break;
        case 3:
          _activePromptType = 'Rasgo de Personaje';
          _generatedOutput = _characterFlaws[_random.nextInt(_characterFlaws.length)];
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<EditorController>(context);
    final bgCard = widget.isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = widget.isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = widget.isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final accentColor = widget.isDark ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
        border: Border.all(color: borderSubtle, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
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

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome_outlined, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inspiración Editorial',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Generador de ideas, escenas y giros narrativos',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Tab options
          TabBar(
            controller: _tabController,
            onTap: (index) => _generatePrompt(index),
            indicatorColor: accentColor,
            labelColor: textPrimary,
            unselectedLabelColor: textSecondary,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Giros'),
              Tab(text: 'Sensorial'),
              Tab(text: 'Diálogos'),
              Tab(text: 'Personaje'),
            ],
          ),

          const SizedBox(height: 16),

          // Prompt Output Display Card
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF191919) : const Color(0xFFF7F6F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _activePromptType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh_rounded, size: 18, color: textPrimary),
                      onPressed: () => _generatePrompt(_tabController.index),
                      tooltip: 'Generar Nueva Idea',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _generatedOutput,
                  style: AppTheme.editorStyle(isDark: widget.isDark, fontSize: 15.0),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 200.ms),

          const SizedBox(height: 20),

          // Action Buttons: Insert into Editor or Save as Scrap
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: borderSubtle),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                  label: const Text('Guardar Nota', style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: () {
                    final newIdea = IdeaSnippetModel(
                      id: 'idea_${DateTime.now().millisecondsSinceEpoch}',
                      title: 'Idea: $_activePromptType',
                      content: _generatedOutput,
                      category: IdeaCategory.general,
                      colorHex: 0xFF18181B,
                      createdAt: DateTime.now(),
                      tags: ['Inspiración', _activePromptType],
                    );
                    controller.addIdea(newIdea);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('¡Idea guardada en tus Notas y Fragmentos!')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: widget.isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.input_rounded, size: 18),
                  label: const Text('Insertar en Texto', style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: () {
                    controller.insertTextToEditor('\n\n/* Idea Editorial: */\n$_generatedOutput\n\n');
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
