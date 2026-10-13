/// Represents a curated literary synonym group with context and stylistic nuances
class SynonymGroup {
  final String headword;
  final String category;
  final String description;
  final List<String> synonyms;
  final Map<String, String> nuances;

  const SynonymGroup({
    required this.headword,
    required this.category,
    required this.description,
    required this.synonyms,
    this.nuances = const {},
  });
}

/// Service providing curated literary synonyms, dialogue verbs, and atmospheric descriptors
class SynonymsService {
  const SynonymsService._();

  static const String catDialogue = 'Verbos de Diálogo y Dicción';
  static const String catMovement = 'Movimiento y Acción';
  static const String catEmotions = 'Emociones y Psicología';
  static const String catAtmosphere = 'Atmósfera y Sensorial';
  static const String catNarrative = 'Cadencia y Conectores Narrativos';

  static final List<SynonymGroup> _database = [
    // --- VERBOS DE DIÁLOGO Y DICCIÓN ---
    SynonymGroup(
      headword: 'decir',
      category: catDialogue,
      description: 'Alternativas al verbo dicendi más reiterativo en la narrativa',
      synonyms: [
        'articular',
        'pronunciar',
        'enunciar',
        'proferir',
        'expresar',
        'manifestar',
        'declarar',
        'afirmar',
        'sostener',
        'sentenciar',
        'comentar',
        'soltar',
      ],
      nuances: {
        'proferir': 'Emitir palabras con fuerza, vehemencia o dolor.',
        'sentenciar': 'Decir algo con tono definitivo, grave o tajante.',
        'articular': 'Pronunciar con deliberada lentitud o esfuerzo.',
        'sostener': 'Mantener una postura o afirmación con firmeza.',
        'soltar': 'Decir algo de forma abrupta, sin pensarlo dos veces.',
      },
    ),
    SynonymGroup(
      headword: 'susurrar',
      category: catDialogue,
      description: 'Hablar en voz queda o con confidencia íntima',
      synonyms: [
        'murmurar',
        'musitar',
        'cuchichear',
        'balbucear',
        'apenas insinuar',
        'mascullar',
        'soplar al oído',
      ],
      nuances: {
        'musitar': 'Hablar entre dientes o en voz tan baja que casi no se oye.',
        'mascullar': 'Pronunciar palabras de forma torpe, molesta o ininteligible.',
        'cuchichear': 'Hablar en secreto de modo que otros no escuchen.',
        'balbucear': 'Pronunciar con vacilación, tartamudez o turbación.',
      },
    ),
    SynonymGroup(
      headword: 'gritar',
      category: catDialogue,
      description: 'Hablar con volumen elevado, angustia o exaltación',
      synonyms: [
        'vociferar',
        'bramar',
        'chillar',
        'rugir',
        'clamar',
        'aullar',
        'desgañitarse',
        'tronar',
        'estallar',
      ],
      nuances: {
        'vociferar': 'Gritar profiriendo injurias, protestas o desorden.',
        'bramar': 'Grito sordo y potente semejante al furor de una fiera o la tempestad.',
        'tronar': 'Gritar con autoridad amenazante y resonante.',
        'clamar': 'Gritar pidiendo socorro, justicia o compasión.',
      },
    ),
    SynonymGroup(
      headword: 'preguntar',
      category: catDialogue,
      description: 'Indagar, formular cuestiones o interrogar',
      synonyms: [
        'inquirir',
        'interrogar',
        'indagar',
        'cuestionar',
        'sondear',
        'demandar',
        'consultar',
      ],
      nuances: {
        'inquirir': 'Preguntar con empeño, curiosidad mordaz o rigor.',
        'sondear': 'Preguntar con cautela para descubrir intenciones ocultas.',
        'interrogar': 'Exigir respuestas formales o bajo presión.',
      },
    ),
    SynonymGroup(
      headword: 'responder',
      category: catDialogue,
      description: 'Contestar, devolver la réplica o justificar',
      synonyms: [
        'replicar',
        'reponer',
        'rebatir',
        'contraatacar',
        'retrucar',
        'admitir',
        'zanjar',
      ],
      nuances: {
        'replicar': 'Responder oponiéndose o manifestando objeciones.',
        'reponer': 'Continuar el hilo del diálogo tras una pausa.',
        'rebatir': 'Refutar con argumentos el punto del interlocutor.',
        'zanjar': 'Responder de forma categórica dando por terminada la discusión.',
      },
    ),

    // --- EMOCIONES Y PSICOLOGÍA ---
    SynonymGroup(
      headword: 'miedo',
      category: catEmotions,
      description: 'Sensación de alarma, peligro o pánico',
      synonyms: [
        'temor',
        'pavor',
        'terror',
        'zozobra',
        'desasosiego',
        'espanto',
        'escalofrío',
        'congoja',
        'aprensión',
        'fobia',
      ],
      nuances: {
        'pavor': 'Miedo intenso que paraliza el cuerpo y la mente.',
        'zozobra': 'Inquietud o desazón continua ante una amenaza incierta.',
        'desasosiego': 'Falta de paz interior provocada por un presentimiento.',
        'congoja': 'Opresión en el pecho originada por una angustia asfixiante.',
      },
    ),
    SynonymGroup(
      headword: 'tristeza',
      category: catEmotions,
      description: 'Pesadumbre, dolor anímico o decaimiento',
      synonyms: [
        'melancolía',
        'desolación',
        'congoja',
        'pesadumbre',
        'amargura',
        'aflicción',
        'abatimiento',
        'pesar',
        'nostalgia',
        'duelo',
      ],
      nuances: {
        'melancolía': 'Tristeza suave, poética y permanente con origen difuso.',
        'desolación': 'Sensación de vacío irremediable y ruina anímica.',
        'abatimiento': 'Pérdida absoluta de energía vital, decaimiento físico.',
        'pesadumbre': 'Carga pesada que oprime la conciencia o el corazón.',
      },
    ),
    SynonymGroup(
      headword: 'ira',
      category: catEmotions,
      description: 'Enojo vehemente, indignación y furor',
      synonyms: [
        'cólera',
        'furia',
        'rabia',
        'indignación',
        'encono',
        'saña',
        'frenesí',
        'irritación',
        'exasperación',
      ],
      nuances: {
        'cólera': 'Ira explosiva acompañada de ademanes vehementes.',
        'encono': 'Rencor persistente y enraizado que busca desquite.',
        'saña': 'Furor despiadado y encarnizado contra la víctima.',
        'frenesí': 'Exaltación desmedida que arrebata el raciocinio.',
      },
    ),
    SynonymGroup(
      headword: 'alegría',
      category: catEmotions,
      description: 'Regocijo, plenitud anímica y felicidad',
      synonyms: [
        'júbilo',
        'regocijo',
        'alborozo',
        'euforia',
        'dicha',
        'plenitud',
        'entusiasmo',
        'gozo',
      ],
      nuances: {
        'júbilo': 'Alegría desbordante que suele exteriorizarse con vivas y risas.',
        'alborozo': 'Regocijo bullicioso y festivo.',
        'dicha': 'Sensación duradera de fortuna, gracia y bienestar.',
        'gozo': 'Deleite íntimo y profundo del espíritu.',
      },
    ),
    SynonymGroup(
      headword: 'sorpresa',
      category: catEmotions,
      description: 'Impacto ante lo inesperado o inexplicable',
      synonyms: [
        'asombro',
        'estupor',
        'perplejidad',
        'desconcierto',
        'incredulidad',
        'estupefacción',
        'consternación',
      ],
      nuances: {
        'estupor': 'Parálisis momentánea de los sentidos ante una noticia impactante.',
        'perplejidad': 'Duda y vacilación por no comprender lo ocurrido.',
        'desconcierto': 'Pérdida de serenidad y orientación.',
        'consternación': 'Sorpresa teñida de abatimiento y dolor moral.',
      },
    ),

    // --- MOVIMIENTO Y ACCIÓN ---
    SynonymGroup(
      headword: 'caminar',
      category: catMovement,
      description: 'Desplazamiento a pie con distintos ritmos o intenciones',
      synonyms: [
        'deambular',
        'vagar',
        'avanzar',
        'marchar',
        'merodear',
        'peregrinar',
        'arrastrarse',
        'desplazarse',
        'transitar',
      ],
      nuances: {
        'deambular': 'Caminar sin rumbo fijo ni prisa.',
        'merodear': 'Caminar sigilosamente alrededor de un lugar vigilando.',
        'arrastrarse': 'Avanzar penosamente con el cuerpo pegado al suelo o agotado.',
        'transitar': 'Recorrer un camino o vía habitual.',
      },
    ),
    SynonymGroup(
      headword: 'correr',
      category: catMovement,
      description: 'Movimiento acelerado, escape o persecución',
      synonyms: [
        'precipitarse',
        'huir',
        'escapar',
        'abalanzarse',
        'lanzarse',
        'esprintar',
        'desbocarse',
      ],
      nuances: {
        'precipitarse': 'Arrojarse o avanzar con peligrosa prisa.',
        'abalanzarse': 'Lanzarse con ímpetu sobre un objetivo o adversario.',
        'desbocarse': 'Correr sin control ni freno como un caballo asustado.',
      },
    ),
    SynonymGroup(
      headword: 'temblar',
      category: catMovement,
      description: 'Vibración involuntaria por frío, miedo o emoción',
      synonyms: [
        'estremecerse',
        'tiritar',
        'titubear',
        'palpitar',
        'trepidar',
        'vacilar',
      ],
      nuances: {
        'estremecerse': 'Temblor repentino causado por una impresión intensa.',
        'tiritar': 'Temblor rítmico producido por el frío o la fiebre.',
        'trepidar': 'Temblar o retumbar con sacudidas bruscas.',
      },
    ),

    // --- ATMÓSFERA Y SENSORIAL ---
    SynonymGroup(
      headword: 'oscuro',
      category: catAtmosphere,
      description: 'Carente de luz, opaco o de matiz inquietante',
      synonyms: [
        'tenebroso',
        'sombrío',
        'lúgubre',
        'lóbrego',
        'opaco',
        'crepuscular',
        'penumbroso',
        'neblinoso',
        'azabache',
      ],
      nuances: {
        'lúgubre': 'Triste, funerario y que infunde terror o melancolía.',
        'lóbrego': 'Profundamente oscuro y húmedo como una caverna.',
        'crepuscular': 'Propio de la luz débil entre el día y la noche.',
        'sombrío': 'Cubierto de sombras o con carácter hosco y melancólico.',
      },
    ),
    SynonymGroup(
      headword: 'brillante',
      category: catAtmosphere,
      description: 'Que emite o refleja luz con intensidad',
      synonyms: [
        'resplandeciente',
        'fulgurante',
        'luminoso',
        'rutilante',
        'centelleante',
        'deslumbrante',
        'refulgente',
        'ígneo',
      ],
      nuances: {
        'fulgurante': 'Que brilla intensamente de forma fugaz como el relámpago.',
        'rutilante': 'Que brilla con destellos vivos y casi metálicos.',
        'refulgente': 'Que emite un resplandor majestuoso y constante.',
        'deslumbrante': 'Luz tan poderosa que ciega o turba la vista.',
      },
    ),
    SynonymGroup(
      headword: 'silencioso',
      category: catAtmosphere,
      description: 'Ausencia de sonido, mutismo o sigilo',
      synonyms: [
        'silente',
        'sigiloso',
        'mudo',
        'taciturno',
        'sosegado',
        'inmóvil',
        'hermético',
      ],
      nuances: {
        'silente': 'Calma poética y solemne exenta de cualquier sonido.',
        'sigiloso': 'Que actúa o se mueve en secreto y con suma cautela.',
        'taciturno': 'Silencioso y reservado por costumbre o tristeza.',
      },
    ),
    SynonymGroup(
      headword: 'frio',
      category: catAtmosphere,
      description: 'Temperatura baja o trato distante y severo',
      synonyms: [
        'gélido',
        'helado',
        'glaciar',
        'invernal',
        'entumecido',
        'cortante',
        'desapacible',
      ],
      nuances: {
        'gélido': 'Extremadamente frío, capaz de congelar el aliento o el ánimo.',
        'cortante': 'Viento o temperatura que duele en la piel como una navaja.',
        'entumecido': 'Miembro o cuerpo privado de sensibilidad por el frío.',
      },
    ),
    SynonymGroup(
      headword: 'antiguo',
      category: catAtmosphere,
      description: 'De épocas pasadas, venerable o desgastado por el tiempo',
      synonyms: [
        'vetusto',
        'ancestral',
        'milenario',
        'arcaico',
        'añejo',
        'inmemorial',
        'caducifolio',
      ],
      nuances: {
        'vetusto': 'Muy viejo, desvencijado o deteriorado por los años.',
        'ancestral': 'Heredado de antepasados remotos.',
        'inmemorial': 'Tan antiguo que escapa a la memoria y los registros.',
      },
    ),

    // --- CADENCIA Y CONECTORES NARRATIVOS ---
    SynonymGroup(
      headword: 'repente',
      category: catNarrative,
      description: 'Acontecimientos imprevistos o que quiebran el ritmo',
      synonyms: [
        'de súbito',
        'intempestivamente',
        'abruptamente',
        'inopinadamente',
        'en un parpadeo',
        'de golpe',
        'sin previo aviso',
      ],
      nuances: {
        'de súbito': 'Cambio imprevisto e instantáneo.',
        'intempestivamente': 'Ocurre fuera de tiempo o en el momento menos oportuno.',
        'inopinadamente': 'Suceso inesperado que no entraba en ninguna hipótesis.',
      },
    ),
    SynonymGroup(
      headword: 'despacio',
      category: catNarrative,
      description: 'Ritmo pausado, deliberado o moroso',
      synonyms: [
        'pausadamente',
        'parsimoniosamente',
        'gradualmente',
        'con lentitud',
        'morosamente',
        'paso a paso',
        'con cautela',
      ],
      nuances: {
        'parsimoniosamente': 'Con extrema calma, lentitud y mesura.',
        'morosamente': 'Lentitud demorada que casi prolonga el suspense.',
      },
    ),
  ];

  /// Common Spanish irregular inflection mappings
  static final Map<String, String> _inflectionMap = {
    'dijo': 'decir',
    'decia': 'decir',
    'decía': 'decir',
    'dijeron': 'decir',
    'dire': 'decir',
    'diré': 'decir',
    'dice': 'decir',
    'dicen': 'decir',
    'susurro': 'susurrar',
    'susurró': 'susurrar',
    'susurraba': 'susurrar',
    'musito': 'susurrar',
    'musitó': 'susurrar',
    'murmuro': 'susurrar',
    'murmuró': 'susurrar',
    'grito': 'gritar',
    'gritó': 'gritar',
    'gritaba': 'gritar',
    'gritaron': 'gritar',
    'pregunto': 'preguntar',
    'preguntó': 'preguntar',
    'pregunta': 'preguntar',
    'inquirio': 'preguntar',
    'inquirić': 'preguntar',
    'inquirió': 'preguntar',
    'respondio': 'responder',
    'respondió': 'responder',
    'responde': 'responder',
    'replico': 'responder',
    'replicó': 'responder',
    'temores': 'miedo',
    'miedos': 'miedo',
    'triste': 'tristeza',
    'tristes': 'tristeza',
    'furioso': 'ira',
    'furiosa': 'ira',
    'enojado': 'ira',
    'alegre': 'alegría',
    'alegres': 'alegría',
    'camino': 'caminar',
    'caminó': 'caminar',
    'caminaba': 'caminar',
    'caminaban': 'caminar',
    'corrio': 'correr',
    'corrió': 'correr',
    'corria': 'correr',
    'corría': 'correr',
    'temblo': 'temblar',
    'tembló': 'temblar',
    'temblaba': 'temblar',
    'oscura': 'oscuro',
    'oscuras': 'oscuro',
    'oscuros': 'oscuro',
    'sombría': 'oscuro',
    'sombrío': 'oscuro',
    'lúgubre': 'oscuro',
    'lugubre': 'oscuro',
    'brillantes': 'brillante',
    'silenciosa': 'silencioso',
    'silenciosos': 'silencioso',
    'fria': 'frio',
    'fría': 'frio',
    'fríos': 'frio',
    'frias': 'frio',
    'antigua': 'antiguo',
    'antiguas': 'antiguo',
    'antiguos': 'antiguo',
  };

  /// Clean normalization helper
  static String normalizeWord(String text) {
    var clean = text.trim().toLowerCase();
    clean = clean.replaceAll(RegExp(r'^[«"“\(\[\{\-—\s]+|[»"”\)\]\}\-—\s,.;:!?]+$'), '');
    return clean;
  }

  /// Remove accents for flexible search comparison
  static String removeAccents(String text) {
    var withAccents = 'áéíóúÁÉÍÓÚñÑüÜ';
    var withoutAccents = 'aeiouAEIOUnNuU';
    var out = text;
    for (int i = 0; i < withAccents.length; i++) {
      out = out.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return out;
  }

  /// Search for synonyms matching a raw word or query
  static List<SynonymGroup> lookup(String query) {
    final clean = normalizeWord(query);
    if (clean.isEmpty) return _database;

    final baseQuery = removeAccents(clean);
    final mappedLemma = _inflectionMap[clean] ?? _inflectionMap[baseQuery];

    final Set<SynonymGroup> results = {};

    // 1. Direct or mapped headword match
    for (final group in _database) {
      final head = removeAccents(group.headword);
      if (head == baseQuery || (mappedLemma != null && head == removeAccents(mappedLemma))) {
        results.add(group);
      }
    }

    // 2. Headword starts with or contains query
    for (final group in _database) {
      final head = removeAccents(group.headword);
      if (head.contains(baseQuery) || baseQuery.contains(head)) {
        results.add(group);
      }
    }

    // 3. Synonym matches
    for (final group in _database) {
      for (final syn in group.synonyms) {
        final normSyn = removeAccents(syn);
        if (normSyn == baseQuery || normSyn.contains(baseQuery)) {
          results.add(group);
          break;
        }
      }
    }

    // 4. Category matches
    if (results.isEmpty) {
      for (final group in _database) {
        if (removeAccents(group.category.toLowerCase()).contains(baseQuery)) {
          results.add(group);
        }
      }
    }

    return results.toList();
  }

  /// Returns all available curated synonym groups
  static List<SynonymGroup> get allGroups => List.unmodifiable(_database);

  /// Returns unique list of categories
  static List<String> get categories => [
        catDialogue,
        catMovement,
        catEmotions,
        catAtmosphere,
        catNarrative,
      ];
}

