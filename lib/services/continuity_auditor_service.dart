import '../models/character_model.dart';
import '../models/codex_entry_model.dart';
import '../models/character_relationship_model.dart';

class DetectedCharacterContinuity {
  final CharacterModel character;
  final int mentions;
  final List<CharacterRelationshipModel> sceneRelationships;

  DetectedCharacterContinuity({
    required this.character,
    required this.mentions,
    required this.sceneRelationships,
  });
}

class DetectedCodexContinuity {
  final CodexEntryModel entry;
  final int mentions;

  DetectedCodexContinuity({
    required this.entry,
    required this.mentions,
  });
}

class ContinuityAuditResult {
  final List<DetectedCharacterContinuity> characters;
  final List<DetectedCodexContinuity> codexEntries;

  const ContinuityAuditResult({
    required this.characters,
    required this.codexEntries,
  });

  bool get isEmpty => characters.isEmpty && codexEntries.isEmpty;
  int get totalItems => characters.length + codexEntries.length;
}

class ContinuityAuditorService {
  /// Scans raw text for mentions of registered characters and lore codex entries
  static ContinuityAuditResult auditContent({
    required String content,
    required List<CharacterModel> allCharacters,
    required List<CodexEntryModel> allCodexEntries,
    required List<CharacterRelationshipModel> allRelationships,
  }) {
    if (content.trim().isEmpty) {
      return const ContinuityAuditResult(characters: [], codexEntries: []);
    }

    final lowerContent = content.toLowerCase();

    // 1. Detect characters
    final Map<String, DetectedCharacterContinuity> detectedChars = {};
    for (final char in allCharacters) {
      final name = char.name.trim();
      if (name.isEmpty) continue;

      final nameLower = name.toLowerCase();
      final regex = RegExp(r'\b' + RegExp.escape(nameLower) + r'\b');
      final matches = regex.allMatches(lowerContent).length;

      if (matches > 0) {
        detectedChars[char.id] = DetectedCharacterContinuity(
          character: char,
          mentions: matches,
          sceneRelationships: [],
        );
      }
    }

    // Correlate scene relationships between detected characters
    final detectedIds = detectedChars.keys.toSet();
    final updatedCharList = <DetectedCharacterContinuity>[];

    for (final detected in detectedChars.values) {
      final charId = detected.character.id;
      final relevantRels = allRelationships.where((r) {
        final matchesSource = r.fromCharacterId == charId && detectedIds.contains(r.toCharacterId);
        final matchesTarget = r.toCharacterId == charId && detectedIds.contains(r.fromCharacterId);
        return matchesSource || (r.isMutual && matchesTarget);
      }).toList();

      updatedCharList.add(DetectedCharacterContinuity(
        character: detected.character,
        mentions: detected.mentions,
        sceneRelationships: relevantRels,
      ));
    }

    // Sort characters by number of mentions descending
    updatedCharList.sort((a, b) => b.mentions.compareTo(a.mentions));

    // 2. Detect Codex Entries
    final detectedCodex = <DetectedCodexContinuity>[];
    for (final entry in allCodexEntries) {
      final name = entry.name.trim();
      if (name.isEmpty) continue;

      final nameLower = name.toLowerCase();
      final regex = RegExp(r'\b' + RegExp.escape(nameLower) + r'\b');
      final matches = regex.allMatches(lowerContent).length;

      if (matches > 0) {
        detectedCodex.add(DetectedCodexContinuity(
          entry: entry,
          mentions: matches,
        ));
      }
    }

    detectedCodex.sort((a, b) => b.mentions.compareTo(a.mentions));

    return ContinuityAuditResult(
      characters: updatedCharList,
      codexEntries: detectedCodex,
    );
  }
}

