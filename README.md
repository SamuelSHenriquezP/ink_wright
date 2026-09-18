# InkWright 🖋️ — Zen Novel Writing & Creative Author Studio

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Desktop-lightgrey)]()
[![Author](https://img.shields.io/badge/Studio-Inventus%20Tech-orange)]()

> **InkWright** es una suite de escritura inmersiva diseñada específicamente para novelistas, dramaturgos y creadores narrativos. Combina un entorno de mecanografía minimalista (*Zen Mode*) con herramientas complejas de ingeniería narrativa: mapas mentales conceptuales, códice de personajes y lore (*Codex*), sprints contrarreloj y persistencia reactiva en tiempo real.

---

## 🌟 Características Principales

* **Entorno de Redacción Zen & Modo Máquina de Escribir (*Typewriter Mode*):**
  * Mantén el foco exacto en la línea actual centrando el cursor verticalmente de manera dinámica.
  * Ocultamiento automático de barras de herramientas y menús mientras se teclea activamente.
  * Formato de texto enriquecido y soporte completo de Markdown en tiempo real (`MarkdownEditingController`).
* **Ingeniería Narrativa & Códice de Mundo (*Codex*):**
  * Fichas completas de personajes con arquetipos, biografías, objetivos y relaciones.
  * Glosario de lore, lugares, cronologías y facciones vinculadas a cada libro.
* **Mapas Mentales Interactivos (*Mind Mapping*):**
  * Lienzo interactivo para conectar nodos argumentales, subtramas y relaciones causa-efecto entre eventos de la historia.
* **Sprints de Escritura & Analíticas de Productividad:**
  * Temporizadores de sprint de escritura con conteo de palabras por minuto (WPM).
  * Estadísticas del escritor: tiempo neto redactando, metas diarias de palabras y progresión por capítulos.
* **Persistencia Blindada con Debounce y Respaldo Dual:**
  * Almacenamiento local asíncrono que no bloquea la UI mediante temporizador inteligente de debounce (`PersistenceService`).
  * Guardado redundante dual (`ink_wright_books` e `ink_wright_books_backup`) para recuperación inmediata ante fallos del sistema operativo.
  * Observador de ciclo de vida (`WidgetsBindingObserver`) que sincroniza automáticamente cualquier palabra pendiente al minimizar la app o cambiar de ventana.

---

## 🏗️ Arquitectura y Estructura del Código

El proyecto sigue una arquitectura desacoplada basada en controladores de estado y servicios dedicados:

```
ink_wright/
├── lib/
│   ├── controllers/
│   │   ├── editor_controller.dart          # Orquestador maestro de estado, selección y persistencia
│   │   └── markdown_editing_controller.dart # Resaltador de sintaxis y renderizado markdown
│   ├── formatters/
│   │   └── writer_text_formatter.dart      # Formateo dinámico y atajos de teclado
│   ├── models/
│   │   ├── book_model.dart                 # Modelo de libros y metadatos
│   │   ├── chapter_model.dart              # Capítulos, texto base y versionado
│   │   ├── chapter_snapshot_model.dart     # Instantáneas históricas para deshacer/rehacer
│   │   ├── character_model.dart            # Fichas narrativas de personajes
│   │   ├── codex_entry_model.dart          # Entradas de enciclopedia del mundo
│   │   ├── mind_map_node_model.dart        # Nodos, conexiones y coordenadas del mapa
│   │   └── writer_stats_model.dart         # Métricas de productividad y sprints
│   ├── screens/
│   │   ├── zen_editor_screen.dart          # Pantalla principal de edición inmersiva
│   │   ├── mind_map_screen.dart            # Lienzo interactivo de mapas mentales
│   │   ├── codex_screen.dart               # Explorador de personajes y lore
│   │   └── sprint_screen.dart              # Módulo de sprints con cronómetro
│   ├── services/
│   │   └── persistence_service.dart        # Motor de persistencia en disco con debounce y backups
│   └── main.dart                           # Inicialización e inyección de estado
```

---

## ⚙️ Especificaciones Técnicas

* **Lenguaje:** Dart 3.x
* **Framework:** Flutter 3.x
* **Gestión de Estado:** `ChangeNotifier` + `Provider`
* **Almacenamiento Local:** `shared_preferences` con serialización JSON tolerante a fallos
* **Renderizado:** Lienzo matricial para mapas mentales y `TextEditingController` personalizado para sintaxis Markdown

---

## 🚀 Puesta en Marcha

1. **Clonar e instalar dependencias:**
   ```bash
   cd ink_wright
   flutter pub get
   ```

2. **Ejecutar en tu dispositivo o emulador:**
   ```bash
   flutter run
   ```

---

**Desarrollado por Inventus Tech Studio** • *Liderado por Samuel Henríquez*
