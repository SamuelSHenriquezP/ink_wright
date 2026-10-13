import '../models/character_model.dart';
import '../models/character_relationship_model.dart';
import '../models/codex_entry_model.dart';
import '../models/idea_snippet_model.dart';

/// Service dedicated to character management, world codex, ideas, and relationship graphs.
class WorldbuildingService {
  const WorldbuildingService._();

  /// Formats character sheet as Markdown text for insertion into the editor
  static String formatCharacterSheet(CharacterModel character) {
    final buffer = StringBuffer();
    buffer.writeln('\n\n## Ficha de Personaje: ${character.name}');
    buffer.writeln('**Rol:** ${character.role} | **Arquetipo:** ${character.archetype}');
    if (character.quote.isNotEmpty) {
      buffer.writeln('> ${character.quote}');
    }
    if (character.traits.isNotEmpty) {
      buffer.writeln('**Rasgos:** ${character.traits.join(', ')}');
    }
    if (character.motivation.isNotEmpty) {
      buffer.writeln('**Motivación:** ${character.motivation}');
    }
    if (character.flawOrGhost.isNotEmpty) {
      buffer.writeln('**Conflicto / Fantasma:** ${character.flawOrGhost}');
    }
    if (character.writtenBiography.isNotEmpty) {
      buffer.writeln('\n### Biografía & Trasfondo\n${character.writtenBiography}');
    }
    buffer.writeln('\n');
    return buffer.toString();
  }

  /// Formats an idea snippet as Markdown comment for insertion into the editor
  static String formatIdeaSnippet(IdeaSnippetModel idea) {
    return '\n\n/* Fragmento de Idea: ${idea.title} */\n${idea.content}\n\n';
  }

  /// Filters relationships involving a specific character in a given book
  static List<CharacterRelationshipModel> filterRelationshipsForCharacter({
    required List<CharacterRelationshipModel> allRelationships,
    required String bookId,
    required String characterId,
  }) {
    return allRelationships
        .where((r) =>
            r.bookId == bookId &&
            (r.fromCharacterId == characterId || r.toCharacterId == characterId))
        .toList();
  }

  /// Adds or scopes a character to the given book ID
  static List<CharacterModel> addCharacter(
    List<CharacterModel> list,
    CharacterModel character,
    String activeBookId,
  ) {
    final scoped = character.bookId.isEmpty ? character.copyWith(bookId: activeBookId) : character;
    return [scoped, ...list];
  }

  /// Updates a character by ID
  static List<CharacterModel> updateCharacter(
    List<CharacterModel> list,
    CharacterModel updated,
  ) {
    return list.map((c) => c.id == updated.id ? updated : c).toList();
  }

  /// Deletes a character by ID and associated relationships
  static (List<CharacterModel>, List<CharacterRelationshipModel>) deleteCharacter(
    List<CharacterModel> characters,
    List<CharacterRelationshipModel> relationships,
    String characterId,
  ) {
    final updatedCharacters = characters.where((c) => c.id != characterId).toList();
    final updatedRelationships = relationships
        .where((r) => r.fromCharacterId != characterId && r.toCharacterId != characterId)
        .toList();
    return (updatedCharacters, updatedRelationships);
  }

  /// Adds or scopes an idea snippet to the given book ID
  static List<IdeaSnippetModel> addIdea(
    List<IdeaSnippetModel> list,
    IdeaSnippetModel idea,
    String activeBookId,
  ) {
    final scoped = idea.bookId.isEmpty ? idea.copyWith(bookId: activeBookId) : idea;
    return [scoped, ...list];
  }

  /// Updates an idea snippet by ID
  static List<IdeaSnippetModel> updateIdea(
    List<IdeaSnippetModel> list,
    IdeaSnippetModel updated,
    String activeBookId,
  ) {
    return list.map((item) {
      if (item.id == updated.id) {
        final bookId = updated.bookId.isNotEmpty ? updated.bookId : item.bookId;
        return updated.copyWith(bookId: bookId.isNotEmpty ? bookId : activeBookId);
      }
      return item;
    }).toList();
  }

  /// Toggles the pinned status of an idea snippet
  static List<IdeaSnippetModel> toggleIdeaPin(
    List<IdeaSnippetModel> list,
    String ideaId,
  ) {
    return list.map((item) {
      if (item.id == ideaId) {
        return item.copyWith(isPinned: !item.isPinned);
      }
      return item;
    }).toList();
  }

  /// Adds or scopes a codex entry to the given book ID
  static List<CodexEntryModel> addCodexEntry(
    List<CodexEntryModel> list,
    CodexEntryModel entry,
    String activeBookId,
  ) {
    final scoped = entry.bookId.isEmpty ? entry.copyWith(bookId: activeBookId) : entry;
    return [scoped, ...list];
  }

  /// Updates a codex entry by ID
  static List<CodexEntryModel> updateCodexEntry(
    List<CodexEntryModel> list,
    CodexEntryModel updated,
    String activeBookId,
  ) {
    return list.map((item) {
      if (item.id == updated.id) {
        final bookId = updated.bookId.isNotEmpty ? updated.bookId : item.bookId;
        return updated.copyWith(bookId: bookId.isNotEmpty ? bookId : activeBookId);
      }
      return item;
    }).toList();
  }

  /// Toggles the pinned status of a codex entry
  static List<CodexEntryModel> toggleCodexPin(
    List<CodexEntryModel> list,
    String entryId,
  ) {
    return list.map((item) {
      if (item.id == entryId) {
        return item.copyWith(isPinned: !item.isPinned);
      }
      return item;
    }).toList();
  }

  /// Adds or scopes a character relationship to the given book ID
  static List<CharacterRelationshipModel> addRelationship(
    List<CharacterRelationshipModel> list,
    CharacterRelationshipModel relationship,
    String activeBookId,
  ) {
    final scoped = relationship.bookId.isEmpty
        ? relationship.copyWith(bookId: activeBookId)
        : relationship;
    return [scoped, ...list];
  }

  /// Updates a character relationship by ID
  static List<CharacterRelationshipModel> updateRelationship(
    List<CharacterRelationshipModel> list,
    CharacterRelationshipModel updated,
  ) {
    return list.map((r) => r.id == updated.id ? updated : r).toList();
  }
}

