import '../models/book_model.dart';
import '../models/chapter_model.dart';
import '../models/idea_snippet_model.dart';
import '../models/codex_entry_model.dart';
import '../models/mind_map_node_model.dart';
import '../models/character_model.dart';
import '../models/writer_stats_model.dart';
import '../models/revision_comment_model.dart';

class InitialSampleData {
  final BookModel activeBook;
  final ChapterModel activeChapter;
  final List<BookModel> allBooks;
  final List<IdeaSnippetModel> ideas;
  final List<CodexEntryModel> codexEntries;
  final List<MindMapNodeModel> mindMapNodes;
  final List<CharacterModel> characters;
  final WriterStatsModel writerStats;

  InitialSampleData({
    required this.activeBook,
    required this.activeChapter,
    required this.allBooks,
    required this.ideas,
    required this.codexEntries,
    required this.mindMapNodes,
    required this.characters,
    required this.writerStats,
  });
}

class InitialSampleDataService {
  static InitialSampleData create() {
    // 1. Starter Tutorial Manuscript (Unico libro inicial de bienvenida)
    final ch1 = ChapterModel(
      id: 'ch_tut_1',
      bookId: 'b_tutorial',
      chapterNumber: 1,
      title: 'Capítulo 1: Bienvenido a tu Estudio & Markdown en Vivo',
      content: '''# Bienvenido a Ink & Wright

Este es tu nuevo santuario de escritura: un espacio minimalista en blanco y negro pensado para que las distracciones desaparezcan y tus palabras cobren vida.

## Escribir con Markdown en Vivo

Mientras escribes en este lienzo, el formato se renderiza en tiempo real:

- Las palabras entre asteriscos dobles se convierten en **negrita editorial**.
- Las palabras entre asteriscos simples adquieren un *tono íntimo en cursiva*.
- Puedes tachar ideas descartadas usando ~~texto tachado~~.
- Escribe fragmentos técnicos o notas de estilo entre comillas invertidas: `escena_climax_01`.

> "Escribir no es añadir adornos, sino retirar la niebla hasta que la historia respire por sí sola."

### Diálogos y Narrativa

Para los diálogos en español, utiliza la raya literaria:

— La tinta guarda secretos que la memoria prefiere olvidar —susurró el archivista mientras cerraba el tomo de cuero.

— Entonces no abras el candado de la biblioteca —respondió ella con calma.

### Tu Lista de Tareas Creativas

- [x] Conocer el editor y probar el Markdown dinámico.
- [ ] Explorar la sección de Personajes en el menú principal.
- [ ] Abrir el Mapa Mental para trazar el arco de tu historia.
- [ ] Probar el modo Pantalla Completa para máxima concentración.

***

Pulsa el icono superior para abrir el panel lateral o vuelve al panel de inicio para comenzar a forjar tu propio manuscrito.''',
      lastEdited: DateTime.now(),
      isCompleted: true,
      notes: 'Capítulo introductorio que enseña las funciones básicas del editor.',
      povCharacter: 'Evelyn Vance',
      comments: [
        RevisionCommentModel(
          id: 'rev_tut_sample_1',
          chapterId: 'ch_tut_1',
          charOffset: 41,
          length: 42,
          commentText: '💡 ¿Cómo funcionan las notas de revisión?\nPuedes seleccionar cualquier fragmento de texto en el editor y pulsar "Nueva Nota" para dejarte anotaciones editoriales, dudas de trama o erratas sin alterar tu texto original. Cuando termines, márcala como "Resolver".',
          highlightedText: 'un espacio minimalista en blanco y negro',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ],
    );

    final ch2 = ChapterModel(
      id: 'ch_tut_2',
      bookId: 'b_tutorial',
      chapterNumber: 2,
      title: 'Capítulo 2: El Arte de Crear Personajes',
      content: '''# Diseñar Personajes con Alma

En la sección de **Personajes**, cada criatura de tu historia tiene su propia ficha narrativa con psicología, deseos y su biografía escrita.

## Los Tres Pilares de un Buen Personaje

1. **El Deseo Consciente:** Lo que el personaje cree que quiere (el objetivo externo).
2. **La Necesidad Inconsciente:** La lección o maduración que debe experimentar para sanar.
3. **El Fantasma o Herida:** Aquello que le ocurrió en el pasado y condiciona sus miedos.

> "Un personaje sin conflicto interno es solo una marioneta con buen vestuario."

### Cómo Usar las Fichas

Puedes consultar tus personajes en cualquier momento, editar su biografía escrita e incluso insertarlos directamente en tu capítulo pulsando "Insertar en Manuscrito".''',
      lastEdited: DateTime.now(),
      isCompleted: false,
      notes: 'Capítulo tutorial sobre la creación y gestión de personajes.',
      povCharacter: 'Evelyn Vance',
    );

    final ch3 = ChapterModel(
      id: 'ch_tut_3',
      bookId: 'b_tutorial',
      chapterNumber: 3,
      title: 'Capítulo 3: Estructuración y Mapa Mental de la Trama',
      content: '''# El Mapa Mental de la Trama

Cada libro en Ink & Wright tiene su propio **Mapa Mental independiente**. Lo que traces para una novela nunca se mezclará con tus otros proyectos.

## Los Actos Narrativos

- **Acto I (Planteamiento):** Presenta el mundo ordinario y el incidente incitador que rompe el equilibrio.
- **Acto II (Nudo y Complicaciones):** El punto medio donde las consecuencias se vuelven irreversibles.
- **Acto III (Clímax y Resolución):** El enfrentamiento decisivo donde el protagonista cambia para siempre.

### Modos del Lienzo

- **Mover y Explorar:** Arrastra el lienzo en cualquier dirección con libertad total.
- **Conectar Nodos:** Toca el botón de conectar en cualquier tarjeta y selecciona el nodo destino para enlazar causas y consecuencias.
- **Auto-Organizar:** Usa el botón de organización automática para ordenar tus ideas en columnas por actos narrativos.''',
      lastEdited: DateTime.now(),
      isCompleted: false,
      notes: 'Capítulo tutorial sobre el mapa mental.',
      povCharacter: 'Evelyn Vance',
    );

    final ch4 = ChapterModel(
      id: 'ch_tut_4',
      bookId: 'b_tutorial',
      chapterNumber: 4,
      title: 'Capítulo 4: El Inspector de Prosa y Pulido de Estilo',
      content: '''# El Laboratorio del Estilo: Inspector de Prosa

En la cabecera de cada capítulo encontrarás el botón `[✨ Inspector]` junto a las métricas de palabras y tiempo de lectura. Esta herramienta actúa como un editor profesional a tu lado.

## ¿Qué analiza el Inspector en Vivo?

El Inspector evalúa tu texto con heurísticas diseñadas específicamente para la narrativa en español:

1. **Puntuación de Legibilidad (Fórmula Fernández-Huerta):**
   Mide la fluidez lectora de 0 a 100. Puntuaciones superiores a 65 indican una prosa ágil y equilibrada.

2. **Adverbios en -mente:**
   Los adverbios (*rápidamente, silenciosamente*) suelen ocultar verbos débiles. Cámbialos por acciones concretas (*echó a correr, contuvo el aliento*).

3. **Oraciones Densas:**
   Oraciones de más de 32 palabras. Considera dividirlas con puntos y seguidos para crear tensión o aliviar al lector.

4. **Ecos Acústicos:**
   Repeticiones involuntarias de la misma palabra dentro del mismo párrafo. Sustitúyelas con sinónimos o reestructura.

5. **Muletillas de Relleno:**
   Palabras como *realmente, prácticamente, simplemente, bastante, un poco, literalmente*. Eliminarlas dota a tu voz de mayor autoridad.

6. **Clichés Literarios:**
   Frases gastadas como *en un abrir y cerrar de ojos*, *frío sepulcral* o *mar de dudas*. Cámbialas por metáforas propias de tu universo.

7. **Voz Pasiva Débil:**
   Estructuras como *fue descubierto por* o *era custodiado*. La voz activa (*el guardián custodiaba*) siempre genera mayor impacto dramático.

8. **Párrafos Densos:**
   Bloques de más de 100 palabras sin punto y aparte. En lectores electrónicos, los párrafos monolíticos fatigan la vista.

> "Escribir es humano, corregir es divino." — Stephen King''',
      lastEdited: DateTime.now(),
      isCompleted: false,
      notes: 'Capítulo tutorial sobre el inspector de prosa y estilo.',
      povCharacter: 'Evelyn Vance',
    );

    final ch5 = ChapterModel(
      id: 'ch_tut_5',
      bookId: 'b_tutorial',
      chapterNumber: 5,
      title: 'Capítulo 5: Caja de Herramientas Editoriales y Modos de Trabajo',
      content: '''# Herramientas Editoriales Avanzadas

Ink & Wright reúne todas las utilidades que un novelista necesita durante las fases de redacción, corrección y maquetación.

## El Menú de Tres Puntos [ ⋮ ]

En la esquina superior derecha del editor tienes acceso directo a:

- **Historial de Versiones (Snapshots):** Congela el estado de tu capítulo antes de hacer una reescritura importante. Puedes restaurar cualquier instante con un solo toque.
- **Notas de Revisión:** Selecciona cualquier frase y añade comentarios marginales para recordar cabos sueltos sin alterar tu texto.
- **Buscar y Reemplazar:** Con sensibilidad a mayúsculas (`Aa`) y la opción de reemplazar en el capítulo o en **todo el libro** a la vez.
- **Modo Máquina de Escribir:** Centra la línea de escritura en la pantalla para relajar la postura.
- **Tipografía y Diseño:** Ajusta tipografías literarias (Lora, Merriweather, Playfair Display, JetBrains Mono), interlineado y ancho de columna.

## Modos de Lectura & Concentración

- **Lector de Manuscrito Completo:** El icono del libro en la barra superior te permite leer todos los capítulos en cascada continua.
- **Sprints de Escritura & Sonidos:** Fija metas de palabras con cronómetro y sumérgete con sonidos ambientales de lluvia, chimenea o cafetería.
- **Tablón de Fichas (Corkboard):** En el panel del libro, visualiza todos tus capítulos como tarjetas de sinopsis.
- **Exportación y Respaldos:** Exporta a PDF, EPUB, TXT o Markdown, y guarda copias de seguridad `.inkwright` para transferir tus novelas a cualquier dispositivo.''',
      lastEdited: DateTime.now(),
      isCompleted: false,
      notes: 'Capítulo tutorial sobre herramientas avanzadas del editor.',
      povCharacter: 'Evelyn Vance',
    );

    final tutorialBook = BookModel(
      id: 'b_tutorial',
      title: 'Manual del Escritor — Guía de Ink & Wright',
      subtitle: 'Tu espacio de escritura, personajes y mapas de trama',
      genre: 'Guía / Tutorial',
      targetWordCount: 25000,
      status: BookStatus.drafting,
      chapters: [ch1, ch2, ch3, ch4, ch5],
      lastEdited: DateTime.now(),
      coverEmoji: '🖋️',
      coverColorHex: 0xFF18181B,
      tags: ['Tutorial', 'Guía', 'Escritura Creativa'],
      synopsis:
          'Una guía viva diseñada para mostrarte cómo escribir con Markdown en tiempo real, dar vida a personajes inolvidables y estructurar tramas visuales.',
    );

    final ideas = [
      IdeaSnippetModel(
        id: 'idea_tut_1',
        bookId: 'b_tutorial',
        title: 'El Secreto de la Biblioteca Olvidada',
        content: 'Un manuscrito donde cada página en blanco revela texto únicamente bajo la luz de la luna llena.',
        category: IdeaCategory.plotTwist,
        colorHex: 0xFF18181B,
        tags: ['Misterio', 'Gótico', 'Trama'],
        createdAt: DateTime.now(),
        isPinned: true,
      ),
      IdeaSnippetModel(
        id: 'idea_tut_2',
        bookId: 'b_tutorial',
        title: 'Diálogo: La promesa del reloj de arena',
        content: '— No te pido una vida entera —dijo el alquimista—. Solo los granos de arena que caen mientras parpadeas.',
        category: IdeaCategory.dialogue,
        colorHex: 0xFF27272A,
        tags: ['Diálogo', 'Fantasía'],
        createdAt: DateTime.now(),
        isPinned: false,
      ),
    ];

    final codexEntries = [
      CodexEntryModel(
        id: 'codex_tut_1',
        bookId: 'b_tutorial',
        name: 'El Archivo de las Horas',
        type: CodexType.location,
        role: 'Biblioteca Histórica Central',
        description: 'Un edificio laberíntico de piedra oscura donde se conservan los diarios perdidos de tres siglos de cronistas.',
        avatarEmoji: '🏛️',
        traits: ['Antiguo', 'Laberíntico', 'Silencioso'],
        secrets: 'Existe un pasadizo subterráneo que conecta con la cripta del gremio de cartógrafos.',
        createdAt: DateTime.now(),
        isPinned: true,
      ),
      CodexEntryModel(
        id: 'codex_tut_2',
        bookId: 'b_tutorial',
        name: 'La Pluma de Azabache',
        type: CodexType.artifact,
        role: 'Reliquia de Escritor',
        description: 'Una pluma tallada en una sola pieza de mineral oscuro. Quien escribe con ella no puede mentir en sus páginas.',
        avatarEmoji: '✒️',
        traits: ['Mágico', 'Incorruptible'],
        secrets: 'Perteneció a la primera cronista del reino antes de que su nombre fuera borrado de los registros.',
        createdAt: DateTime.now(),
        isPinned: true,
      ),
    ];

    final mindMapNodes = [
      MindMapNodeModel(
        id: 'node_tut_1',
        bookId: 'b_tutorial',
        title: 'Acto I: Conoce tu Espacio de Escritura',
        description: 'Aprende a usar el editor con Markdown en vivo, las tipografías y el modo de pantalla completa.',
        act: PlotAct.act1Exposition,
        type: PlotNodeType.turningPoint,
        dx: 80,
        dy: 120,
        connectedToIds: ['node_tut_2'],
        colorHex: 0xFF18181B,
        iconEmoji: '🖋️',
      ),
      MindMapNodeModel(
        id: 'node_tut_2',
        bookId: 'b_tutorial',
        title: 'Acto II: Diseña tus Personajes y Fichas',
        description: 'Crea personajes con psicología, deseos y su biografía narrativa completa.',
        act: PlotAct.midpoint,
        type: PlotNodeType.characterArc,
        dx: 480,
        dy: 120,
        connectedToIds: ['node_tut_3'],
        colorHex: 0xFF27272A,
        iconEmoji: '👤',
      ),
      MindMapNodeModel(
        id: 'node_tut_3',
        bookId: 'b_tutorial',
        title: 'Acto III: Escribe y Estructura tu Trama',
        description: 'Traza causas y consecuencias en el lienzo infinito y exporta tu manuscrito.',
        act: PlotAct.act3Climax,
        type: PlotNodeType.mainPlot,
        dx: 880,
        dy: 120,
        connectedToIds: [],
        colorHex: 0xFF18181B,
        iconEmoji: '📖',
      ),
    ];

    final characters = [
      CharacterModel(
        id: 'char_tut_1',
        bookId: 'b_tutorial',
        name: 'Evelyn Vance',
        role: 'Protagonista',
        archetype: 'La Investigadora Renuente',
        traits: ['Observadora', 'Metódica', 'Intuitiva'],
        physicalAppearance: 'Mirada atenta de ojos grises, gabardina oscura con marcas de tinta en los puños y un reloj de bolsillo antiguo.',
        motivation: 'Descifrar los manuscritos olvidados de la antigua biblioteca de Blackwood.',
        flawOrGhost: 'Teme equivocarse y repetir el error que le costó el puesto a su mentor.',
        characterArc: 'Pasa de dudar de sus instintos a liderar la investigación con determinación inquebrantable.',
        writtenBiography: '''Evelyn nació en una familia de encuadernadores y archivistas. Creció entre olor a cuero viejo, papel secante y tinta ferrogálica. Posee una memoria prodigiosa para las palabras no dichas y los márgenes de los textos antiguos, donde los escritores solían anotar sus verdades más peligrosas.

A los veintiocho años, heredó el taller de su abuelo junto con un baúl de notas que nadie había logrado descifrar. Su vida cambió el día que encontró un pliego con el sello intacto del Gremio.''',
        quote: '«Los márgenes de los libros siempre revelan más que los textos impresos.»',
        avatarEmoji: '🕵️‍♀️',
        createdAt: DateTime.now(),
      ),
    ];

    final writerStats = WriterStatsModel(
      wordsToday: 850,
      dailyGoalWords: 2000,
      streakDays: 3,
      totalWordsWritten: 12500,
      writingTimeTodayMinutes: 35,
      wordsPerMinuteAvg: 30,
      focusScore: 95,
      weeklyProgress: {
        'Lun': 1200,
        'Mar': 1500,
        'Mié': 850,
        'Jue': 1100,
        'Vie': 1400,
        'Sáb': 900,
        'Dom': 850,
      },
    );

    return InitialSampleData(
      activeBook: tutorialBook,
      activeChapter: ch1,
      allBooks: [tutorialBook],
      ideas: ideas,
      codexEntries: codexEntries,
      mindMapNodes: mindMapNodes,
      characters: characters,
      writerStats: writerStats,
    );
  }
}
