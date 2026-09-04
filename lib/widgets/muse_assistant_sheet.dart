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
  String _activePromptType = 'Plot Twist';

  // Sample prompt engine datasets
  final List<String> _plotTwists = [
    "The ancient silver compass doesn't point to St. Jude's Abbey; it tracks the location of Silas's missing shadow.",
    "Martha isn't keeping secrets from Silas; she was sent by the Guild to erase his memories of the valley.",
    "The fog across Blackwood Valley only moves when someone lies within three miles of the sanctuary.",
    "The maps Silas drew thirty years ago didn't record terrain—they prophesied the future collapse of the monastery.",
    "The clock tower in St. Jude's doesn't ring for hours; it tolls whenever a chapter of the town's history is altered.",
  ];

  final List<String> _sensoryDetails = [
    "Damp peat moss, stale tallow candle smoke, and the faint metallic tang of old brass after rain.",
    "A cold draft swept through the floorboards, smelling of pine needle pitch and forgotten parchment.",
    "The silence was heavy, broken only by the synchronized ticking of two pocket watches set 12 seconds apart.",
    "Pale moonlight filtered through stained glass, casting cobalt and crimson geometric shadows across the cobblestone.",
  ];

  final List<String> _dialogueSparks = [
    "\"If we stop writing the story now, Silas, the story will start writing us.\"",
    "\"A secret buried in wet soil doesn't rot; it grows roots.\"",
    "\"Do not trust a map drawn by someone who survived the night at St. Jude's.\"",
    "\"The mountain remembers every word you whispered in the dark.\"",
  ];

  final List<String> _characterFlaws = [
    "Uncompromising obsession with cartographic precision even when under fire.",
    "Refuses to read letters written after dusk out of superstitious dread.",
    "Hides an old brass key inside the binding of every book he touches.",
    "Hears distant bell chimes whenever he makes a fateful decision.",
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
          _activePromptType = 'Plot Twist';
          _generatedOutput = _plotTwists[_random.nextInt(_plotTwists.length)];
          break;
        case 1:
          _activePromptType = 'Sensory Details';
          _generatedOutput = _sensoryDetails[_random.nextInt(_sensoryDetails.length)];
          break;
        case 2:
          _activePromptType = 'Evocative Dialogue';
          _generatedOutput = _dialogueSparks[_random.nextInt(_dialogueSparks.length)];
          break;
        case 3:
          _activePromptType = 'Character Trait';
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
    final accentMint = widget.isDark ? AppTheme.darkAccentMint : AppTheme.lightAccentMint;

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
                      color: accentMint.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text('✨', style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'The Muse Studio',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Creative prompts & narrative sparks',
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
            indicatorColor: accentMint,
            labelColor: accentMint,
            unselectedLabelColor: textSecondary,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Plot Twist'),
              Tab(text: 'Sensory'),
              Tab(text: 'Dialogue'),
              Tab(text: 'Character'),
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
                        color: accentMint,
                        letterSpacing: 1.0,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh_rounded, size: 18, color: accentMint),
                      onPressed: () => _generatePrompt(_tabController.index),
                      tooltip: 'Generate New Spark',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _generatedOutput,
                  style: AppTheme.editorStyle(isDark: widget.isDark, fontSize: 15.5),
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
                  label: const Text('Save to Ideas', style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: () {
                    final newIdea = IdeaSnippetModel(
                      id: 'idea_${DateTime.now().millisecondsSinceEpoch}',
                      title: '$_activePromptType Spark',
                      content: _generatedOutput,
                      category: IdeaCategory.plotTwist,
                      colorHex: 0xFF38C793,
                      createdAt: DateTime.now(),
                      tags: ['Creative Spark', _activePromptType],
                    );
                    controller.addIdea(newIdea);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved spark to Ideas & Scraps!')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentMint,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.input_rounded, size: 18),
                  label: const Text('Insert to Editor', style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: () {
                    controller.insertTextToEditor('\n\n/* Muse Spark: */\n$_generatedOutput\n\n');
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
