/// Enum representing the category of a prose critique issue.
enum ProseIssueType {
  adverb,
  longSentence,
  echo,
  fillerWord,
  cliche,
  passiveVoice,
  longParagraph,
}

/// A specific highlighted issue within the analysed prose.
class ProseIssue {
  final ProseIssueType type;
  final int startIndex;
  final int endIndex;
  final String matchedText;
  final String message;
  final String suggestion;

  const ProseIssue({
    required this.type,
    required this.startIndex,
    required this.endIndex,
    required this.matchedText,
    required this.message,
    required this.suggestion,
  });

  String get typeLabel {
    switch (type) {
      case ProseIssueType.adverb:
        return 'Adverbio en -mente';
      case ProseIssueType.longSentence:
        return 'Oración densa';
      case ProseIssueType.echo:
        return 'Eco / Repetición';
      case ProseIssueType.fillerWord:
        return 'Muletilla de relleno';
      case ProseIssueType.cliche:
        return 'Cliché literario';
      case ProseIssueType.passiveVoice:
        return 'Voz pasiva débil';
      case ProseIssueType.longParagraph:
        return 'Párrafo denso';
    }
  }
}

/// Diagnostic metrics calculated for a manuscript chapter.
class ProseAnalysisResult {
  final int totalWords;
  final int totalSentences;
  final int totalParagraphs;
  final double averageWordsPerSentence;
  final int adverbsCount;
  final int longSentencesCount;
  final int echoesCount;
  final int fillerWordsCount;
  final int clichesCount;
  final int passiveVoiceCount;
  final int longParagraphsCount;
  final double readabilityScore; // 0 - 100
  final String readabilityLabel;
  final List<ProseIssue> issues;

  const ProseAnalysisResult({
    required this.totalWords,
    required this.totalSentences,
    required this.totalParagraphs,
    required this.averageWordsPerSentence,
    required this.adverbsCount,
    required this.longSentencesCount,
    required this.echoesCount,
    this.fillerWordsCount = 0,
    this.clichesCount = 0,
    this.passiveVoiceCount = 0,
    this.longParagraphsCount = 0,
    required this.readabilityScore,
    required this.readabilityLabel,
    required this.issues,
  });
}

/// Fast, dedicated heuristic engine for Spanish novel prose analysis (Hemingway/ProWritingAid style).
class ProseStyleAnalyzerService {
  const ProseStyleAnalyzerService._();

  // Common Spanish grammatical stopwords to exclude when scanning for word repetition echoes
  static const Set<String> _stopwords = {
    'cuando', 'porque', 'aunque', 'despues', 'después', 'entonces', 'tambien',
    'también', 'ademas', 'además', 'mientras', 'durante', 'algunos', 'algunas',
    'siempre', 'todavia', 'todavía', 'hubiera', 'estaba', 'estaban', 'habian',
    'habían', 'parecia', 'parecía', 'sentia', 'sentía', 'contra', 'dentro',
    'fueron', 'estuvo', 'hubiese', 'aquellos', 'aquellas', 'propio', 'propia',
    'nuestro', 'nuestra', 'primer', 'primero', 'primera', 'segundo', 'ningun',
    'ningún', 'ninguno', 'ninguna', 'delante', 'detras', 'detrás', 'alrededor',
  };

  static const List<String> _cliches = [
    'en un abrir y cerrar de ojos',
    'de la noche a la mañana',
    'de la noche a la manana',
    'frío sepulcral',
    'frio sepulcral',
    'un frío sepulcral',
    'el corazón le dio un vuelco',
    'el corazon le dio un vuelco',
    'un vuelco al corazón',
    'un vuelco al corazon',
    'contra viento y marea',
    'un mar de dudas',
    'mar de dudas',
    'oscuridad impenetrable',
    'silencio sepulcral',
    'un silencio sepulcral',
    'a flor de piel',
    'como caído del cielo',
    'como caido del cielo',
    'más claro que el agua',
    'mas claro que el agua',
    'de pies a cabeza',
    'punto de no retorno',
    'un rayo de esperanza',
    'sudor frío',
    'sudor frio',
    'lágrimas de cocodrilo',
    'lagrimas de cocodrilo',
    'correr como alma que lleva el diablo',
    'temblar como una hoja',
    'bajar la guardia',
    'arma de doble filo',
  ];

  /// Analyzes the supplied text and returns diagnostics with exact character ranges.
  static ProseAnalysisResult analyze(String rawText) {
    if (rawText.trim().isEmpty) {
      return const ProseAnalysisResult(
        totalWords: 0,
        totalSentences: 0,
        totalParagraphs: 0,
        averageWordsPerSentence: 0,
        adverbsCount: 0,
        longSentencesCount: 0,
        echoesCount: 0,
        fillerWordsCount: 0,
        clichesCount: 0,
        passiveVoiceCount: 0,
        longParagraphsCount: 0,
        readabilityScore: 100,
        readabilityLabel: 'Vacío',
        issues: [],
      );
    }

    final issues = <ProseIssue>[];

    // 1. Detect adverbs ending in -mente (with at least 6 letters: e.g. lentamente, rapido -> rapidamente)
    final adverbRegex = RegExp(r'\b([a-záéíóúñA-ZÁÉÍÓÚÑ]{4,}mente)\b', caseSensitive: false);
    int adverbsCount = 0;
    for (final match in adverbRegex.allMatches(rawText)) {
      final matchedStr = match.group(1)!;
      final lower = matchedStr.toLowerCase();
      // Filter false positives in Spanish
      if (lower == 'demente' || lower == 'simiente' || lower == 'torrente' || lower == 'suficiente') {
        continue;
      }
      adverbsCount++;
      issues.add(ProseIssue(
        type: ProseIssueType.adverb,
        startIndex: match.start,
        endIndex: match.end,
        matchedText: matchedStr,
        message: 'Uso de adverbio en "-mente" ("$matchedStr").',
        suggestion: 'Los grandes novelistas recomiendan sustituirlos por un verbo o acción más vívida.',
      ));
    }

    // 2. Sentence splitting & Long sentences detection (> 32 words)
    final sentenceRegex = RegExp(r'[^.!?\n]+[.!?]?', multiLine: true);
    int sentenceCount = 0;
    int longSentencesCount = 0;
    int totalWordsInSentences = 0;

    for (final match in sentenceRegex.allMatches(rawText)) {
      final sentenceStr = match.group(0)?.trim() ?? '';
      if (sentenceStr.isEmpty) continue;

      final words = sentenceStr.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      if (words.isEmpty) continue;

      sentenceCount++;
      totalWordsInSentences += words.length;

      if (words.length > 32) {
        longSentencesCount++;
        final preview = sentenceStr.length > 60 ? '${sentenceStr.substring(0, 60)}...' : sentenceStr;
        issues.add(ProseIssue(
          type: ProseIssueType.longSentence,
          startIndex: match.start,
          endIndex: match.end,
          matchedText: preview,
          message: 'Oración densa de ${words.length} palabras.',
          suggestion: 'Considera dividirla con un punto y seguido para oxigenar el ritmo de lectura.',
        ));
      }
    }

    // 3. Detect echoes / repetitions & Long paragraphs inside each paragraph
    final paragraphs = rawText.split('\n');
    int echoesCount = 0;
    int longParagraphsCount = 0;
    int cumulativeIndex = 0;

    for (final para in paragraphs) {
      final trimmedPara = para.trim();
      if (trimmedPara.isNotEmpty) {
        final paraWords = trimmedPara.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        if (paraWords.length > 100) {
          longParagraphsCount++;
          final preview = trimmedPara.length > 70 ? '${trimmedPara.substring(0, 70)}...' : trimmedPara;
          issues.add(ProseIssue(
            type: ProseIssueType.longParagraph,
            startIndex: cumulativeIndex,
            endIndex: cumulativeIndex + para.length,
            matchedText: preview,
            message: 'Párrafo denso de ${paraWords.length} palabras.',
            suggestion: 'Un muro de texto continuo fatiga la vista. Añadir puntos y aparte oxigena la narrativa.',
          ));
        }
      }

      if (para.trim().length > 30) {
        final wordRegex = RegExp(r'\b([a-záéíóúñA-ZÁÉÍÓÚÑ]{5,})\b');
        final wordOccurrences = <String, List<Match>>{};

        for (final m in wordRegex.allMatches(para)) {
          final word = m.group(1)!.toLowerCase();
          if (!_stopwords.contains(word)) {
            wordOccurrences.putIfAbsent(word, () => []).add(m);
          }
        }

        wordOccurrences.forEach((word, matches) {
          if (matches.length >= 2) {
            echoesCount++;
            for (final m in matches) {
              issues.add(ProseIssue(
                type: ProseIssueType.echo,
                startIndex: cumulativeIndex + m.start,
                endIndex: cumulativeIndex + m.end,
                matchedText: m.group(1)!,
                message: 'Eco: La palabra "$word" se repite ${matches.length} veces en este mismo párrafo.',
                suggestion: 'Usa un sinónimo o reestructura para evitar monotonía acústica.',
              ));
            }
          }
        });
      }
      cumulativeIndex += para.length + 1; // +1 for the newline
    }

    // 4. Detect Filler Words (Muletillas debilitantes)
    final fillerRegex = RegExp(
      r'\b(realmente|simplemente|prácticamente|practicamente|bastante|un poco|literalmente|apenas|quizás|quizas|tal vez|ciertamente|definitivamente|francamente|verdaderamente)\b',
      caseSensitive: false,
    );
    int fillerWordsCount = 0;
    for (final match in fillerRegex.allMatches(rawText)) {
      final matchedStr = match.group(0)!;
      fillerWordsCount++;
      issues.add(ProseIssue(
        type: ProseIssueType.fillerWord,
        startIndex: match.start,
        endIndex: match.end,
        matchedText: matchedStr,
        message: 'Muletilla de relleno ("$matchedStr").',
        suggestion: 'Eliminar modificadores superfluos otorga mayor peso y seguridad al tono narrativo.',
      ));
    }

    // 5. Detect Clichés literarios
    int clichesCount = 0;
    for (final cliche in _cliches) {
      final clicheRegex = RegExp('\\b${RegExp.escape(cliche)}\\b', caseSensitive: false);
      for (final match in clicheRegex.allMatches(rawText)) {
        clichesCount++;
        issues.add(ProseIssue(
          type: ProseIssueType.cliche,
          startIndex: match.start,
          endIndex: match.end,
          matchedText: match.group(0)!,
          message: 'Cliché común detectado ("${match.group(0)!}").',
          suggestion: 'Crea una imagen visual o metáfora original que evoque la singularidad de tu mundo.',
        ));
      }
    }

    // 6. Detect Passive Voice (Voz pasiva compuesta débil)
    final passiveRegex = RegExp(
      r'\b(fue|fueron|era|eran|había sido|habian sido|ha sido|han sido|será|sera|serán|seran)\s+([a-záéíóúñA-ZÁÉÍÓÚÑ]+(?:ado|ada|ados|adas|ido|ida|idos|idas|to|ta|tos|tas|so|sa|sos|sas|cho|cha|chos|chas))\b',
      caseSensitive: false,
    );
    int passiveVoiceCount = 0;
    for (final match in passiveRegex.allMatches(rawText)) {
      final participle = match.group(2)!.toLowerCase();
      if (participle == 'todo' || participle == 'toda' || participle == 'todos' || participle == 'todas' || participle == 'solo' || participle == 'sola') {
        continue;
      }
      final matchedStr = match.group(0)!;
      passiveVoiceCount++;
      issues.add(ProseIssue(
        type: ProseIssueType.passiveVoice,
        startIndex: match.start,
        endIndex: match.end,
        matchedText: matchedStr,
        message: 'Construcción en voz pasiva ("$matchedStr").',
        suggestion: 'Dar protagonismo al sujeto en voz activa genera mayor inmersión y energía dramática.',
      ));
    }

    // Sort issues by appearance in text
    issues.sort((a, b) => a.startIndex.compareTo(b.startIndex));

    // Calculate Readability (Fernández-Huerta readability formula for Spanish)
    final wordsCount = rawText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final paragraphsCount = paragraphs.where((p) => p.trim().isNotEmpty).length;
    final avgWordsPerSentence = sentenceCount > 0 ? totalWordsInSentences / sentenceCount : 0.0;

    // Approximate syllables count in Spanish
    final syllableRegex = RegExp(r'[aeiouáéíóúüAEIOUÁÉÍÓÚÜ]+');
    final totalSyllables = syllableRegex.allMatches(rawText).length;
    final p = wordsCount > 0 ? (totalSyllables / wordsCount) * 100.0 : 0.0;
    final f = sentenceCount > 0 ? (wordsCount / sentenceCount) : 0.0;

    // Huerta Formula: 206.84 - (0.60 * P) - (1.02 * F)
    final calculatedScore = (206.84 - (0.60 * p) - (1.02 * f)).clamp(0.0, 100.0);

    String readabilityLabel;
    if (calculatedScore >= 80) {
      readabilityLabel = 'Muy ágil y ligera';
    } else if (calculatedScore >= 65) {
      readabilityLabel = 'Fluida y equilibrada';
    } else if (calculatedScore >= 50) {
      readabilityLabel = 'Estilo estándar';
    } else if (calculatedScore >= 35) {
      readabilityLabel = 'Densa / Compleja';
    } else {
      readabilityLabel = 'Muy difícil / Barroca';
    }

    return ProseAnalysisResult(
      totalWords: wordsCount,
      totalSentences: sentenceCount,
      totalParagraphs: paragraphsCount,
      averageWordsPerSentence: double.parse(avgWordsPerSentence.toStringAsFixed(1)),
      adverbsCount: adverbsCount,
      longSentencesCount: longSentencesCount,
      echoesCount: echoesCount,
      fillerWordsCount: fillerWordsCount,
      clichesCount: clichesCount,
      passiveVoiceCount: passiveVoiceCount,
      longParagraphsCount: longParagraphsCount,
      readabilityScore: double.parse(calculatedScore.toStringAsFixed(1)),
      readabilityLabel: readabilityLabel,
      issues: issues,
    );
  }
}

