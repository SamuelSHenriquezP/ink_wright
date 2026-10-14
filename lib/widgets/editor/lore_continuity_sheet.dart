import 'package:flutter/material.dart';
import '../../models/character_model.dart';
import '../../models/character_relationship_model.dart';
import '../../models/codex_entry_model.dart';
import '../../services/continuity_auditor_service.dart';
import '../../theme/app_theme.dart';

class LoreContinuitySheet extends StatefulWidget {
  final bool isDark;
  final String chapterTitle;
  final String chapterContent;
  final List<CharacterModel> allCharacters;
  final List<CodexEntryModel> allCodexEntries;
  final List<CharacterRelationshipModel> allRelationships;
  final bool isContinuityAuditorEnabled;
  final ValueChanged<bool> onToggleEnabled;
  final void Function(String text)? onInsertText;

  const LoreContinuitySheet({
    super.key,
    required this.isDark,
    required this.chapterTitle,
    required this.chapterContent,
    required this.allCharacters,
    required this.allCodexEntries,
    required this.allRelationships,
    required this.isContinuityAuditorEnabled,
    required this.onToggleEnabled,
    this.onInsertText,
  });

  static void show({
    required BuildContext context,
    required bool isDark,
    required String chapterTitle,
    required String chapterContent,
    required List<CharacterModel> allCharacters,
    required List<CodexEntryModel> allCodexEntries,
    required List<CharacterRelationshipModel> allRelationships,
    required bool isContinuityAuditorEnabled,
    required ValueChanged<bool> onToggleEnabled,
    void Function(String text)? onInsertText,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LoreContinuitySheet(
        isDark: isDark,
        chapterTitle: chapterTitle,
        chapterContent: chapterContent,
        allCharacters: allCharacters,
        allCodexEntries: allCodexEntries,
        allRelationships: allRelationships,
        isContinuityAuditorEnabled: isContinuityAuditorEnabled,
        onToggleEnabled: onToggleEnabled,
        onInsertText: onInsertText,
      ),
    );
  }

  @override
  State<LoreContinuitySheet> createState() => _LoreContinuitySheetState();
}

class _LoreContinuitySheetState extends State<LoreContinuitySheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ContinuityAuditResult _auditResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _runAudit();
  }

  @override
  void didUpdateWidget(covariant LoreContinuitySheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapterContent != widget.chapterContent ||
        oldWidget.allCharacters != widget.allCharacters ||
        oldWidget.allCodexEntries != widget.allCodexEntries ||
        oldWidget.allRelationships != widget.allRelationships) {
      _runAudit();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _runAudit() {
    _auditResult = ContinuityAuditorService.auditContent(
      content: widget.chapterContent,
      allCharacters: widget.allCharacters,
      allCodexEntries: widget.allCodexEntries,
      allRelationships: widget.allRelationships,
    );
  }

  String _getCharacterName(String charId) {
    final char = widget.allCharacters.firstWhere(
      (c) => c.id == charId,
      orElse: () => CharacterModel(
        id: '',
        bookId: '',
        name: 'Desconocido',
        role: 'Secundario',
      ),
    );
    return char.name;
  }

  @override
  Widget build(BuildContext context) {
    final bgCard = widget.isDark ? const Color(0xFF1E1E22) : Colors.white;
    final textPrimary =
        widget.isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle =
        widget.isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final cardBg =
        widget.isDark ? const Color(0xFF26262B) : const Color(0xFFF8F9FA);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.accentTeal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.fact_check_rounded,
                      color: AppTheme.accentTeal,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auditor de Continuidad',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.chapterTitle.isNotEmpty
                              ? widget.chapterTitle
                              : 'Capítulo Activo',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Optional Switch Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.isContinuityAuditorEnabled
                          ? Icons.radar_rounded
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: widget.isContinuityAuditorEnabled
                          ? AppTheme.accentTeal
                          : textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seguimiento de Continuidad',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            widget.isContinuityAuditorEnabled
                                ? 'Detectando personajes y códice en tiempo real'
                                : 'Opcional: Actívalo para auditar la escena',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: widget.isContinuityAuditorEnabled,
                      activeColor: AppTheme.accentTeal,
                      onChanged: (val) {
                        widget.onToggleEnabled(val);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppTheme.accentTeal.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.accentTeal.withValues(alpha: 0.4),
                    ),
                  ),
                  labelColor: AppTheme.accentTeal,
                  unselectedLabelColor: textSecondary,
                  labelStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.normal,
                  ),
                  tabs: [
                    Tab(
                      text:
                          'Personajes (${_auditResult.characters.length})',
                    ),
                    Tab(
                      text:
                          'Códice & Lore (${_auditResult.codexEntries.length})',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCharactersTab(textPrimary, textSecondary, borderSubtle, cardBg),
                  _buildCodexTab(textPrimary, textSecondary, borderSubtle, cardBg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharactersTab(
    Color textPrimary,
    Color textSecondary,
    Color borderSubtle,
    Color cardBg,
  ) {
    if (_auditResult.characters.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_search_rounded,
                size: 46,
                color: textSecondary.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'No se detectaron personajes en este capítulo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Asegúrate de registrar tus personajes en la pestaña Códice/Personajes y nombrarlos en el texto.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: _auditResult.characters.length,
      itemBuilder: (context, index) {
        final detected = _auditResult.characters[index];
        final char = detected.character;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + Mention Chip + Insert
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.accentTeal.withValues(alpha: 0.15),
                    child: Text(
                      char.name.isNotEmpty ? char.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppTheme.accentTeal,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          char.name,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${char.role.isNotEmpty ? char.role : "Personaje"} • ${char.archetype.isNotEmpty ? char.archetype : "Sin arquetipo"}',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${detected.mentions} ${detected.mentions == 1 ? "mención" : "menciones"}',
                      style: const TextStyle(
                        color: AppTheme.accentTeal,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              // Traits / Appearance / Flaws
              if (char.physicalAppearance.isNotEmpty ||
                  char.flawOrGhost.isNotEmpty ||
                  char.motivation.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                if (char.physicalAppearance.isNotEmpty)
                  _buildTraitRow(
                    Icons.face_rounded,
                    'Físico:',
                    char.physicalAppearance,
                    textPrimary,
                    textSecondary,
                  ),
                if (char.flawOrGhost.isNotEmpty)
                  _buildTraitRow(
                    Icons.warning_amber_rounded,
                    'Defecto / Fantasma:',
                    char.flawOrGhost,
                    textPrimary,
                    textSecondary,
                  ),
                if (char.motivation.isNotEmpty)
                  _buildTraitRow(
                    Icons.flag_rounded,
                    'Motivación:',
                    char.motivation,
                    textPrimary,
                    textSecondary,
                  ),
              ],

              // Scene Relationships
              if (detected.sceneRelationships.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? const Color(0xFF1B1B1E)
                        : const Color(0xFFF1F3F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.hub_rounded,
                            size: 14,
                            color: AppTheme.accentTeal,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Vínculos con otros personajes en escena:',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...detected.sceneRelationships.map((rel) {
                        final otherId = rel.fromCharacterId == char.id
                            ? rel.toCharacterId
                            : rel.fromCharacterId;
                        final otherName = _getCharacterName(otherId);

                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                rel.type.iconData,
                                size: 14,
                                color: Color(rel.type.colorHex),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${rel.type.label} con $otherName' +
                                      (rel.description.isNotEmpty
                                          ? ': "${rel.description}"'
                                          : ''),
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],

              // Quick paste trait button
              if (widget.onInsertText != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.add_comment_rounded, size: 14),
                    label: const Text(
                      'Insertar ficha al texto',
                      style: TextStyle(fontSize: 11),
                    ),
                    onPressed: () {
                      final summary = '> **[Continuidad: ${char.name}]** '
                          '${char.physicalAppearance.isNotEmpty ? "Físico: " + char.physicalAppearance + ". " : ""}'
                          '${char.motivation.isNotEmpty ? "Motivación: " + char.motivation : ""}\n\n';
                      widget.onInsertText!(summary);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCodexTab(
    Color textPrimary,
    Color textSecondary,
    Color borderSubtle,
    Color cardBg,
  ) {
    if (_auditResult.codexEntries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_stories_rounded,
                size: 46,
                color: textSecondary.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'No se mencionan entradas del códice en este capítulo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Crea entradas de lugares, objetos o lore en el Códice y menciónalas en el texto para auditar su lore.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: _auditResult.codexEntries.length,
      itemBuilder: (context, index) {
        final detected = _auditResult.codexEntries[index];
        final entry = detected.entry;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.accentTeal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        entry.iconData,
                        size: 20,
                        color: AppTheme.accentTeal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.name,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          entry.typeLabel,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${detected.mentions} ${detected.mentions == 1 ? "mención" : "menciones"}',
                      style: const TextStyle(
                        color: AppTheme.accentTeal,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (entry.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Text(
                  entry.description,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (entry.traits.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: entry.traits.map((trait) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: borderSubtle.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#$trait',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTraitRow(
    IconData icon,
    String label,
    String value,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppTheme.accentTeal),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textSecondary,
                fontSize: 11.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

