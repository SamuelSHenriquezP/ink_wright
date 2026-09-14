import 'package:flutter/material.dart';

enum PlotAct {
  prologue,
  act1Exposition,
  act2RisingAction,
  midpoint,
  act3Climax,
  act4Fallout,
  act5Resolution,
  resolution,
  epilogue,
  custom,
}

enum PlotNodeType {
  mainPlot,
  subplot,
  characterArc,
  worldLore,
  turningPoint,
}

class MindMapNodeModel {
  final String id;
  final String bookId;
  final String title;
  final String description;
  final PlotAct act;
  final String? customActName;
  final PlotNodeType type;
  final double dx;
  final double dy;
  final List<String> connectedToIds;
  final int colorHex;
  final String iconEmoji;
  final String? linkedChapterId;

  MindMapNodeModel({
    required this.id,
    required this.bookId,
    required this.title,
    required this.description,
    required this.act,
    this.customActName,
    required this.type,
    required this.dx,
    required this.dy,
    required this.connectedToIds,
    required this.colorHex,
    required this.iconEmoji,
    this.linkedChapterId,
  });

  String get actLabel {
    if (act == PlotAct.custom && customActName != null && customActName!.isNotEmpty) {
      return customActName!;
    }
    return act.label;
  }

  String get typeLabel => type.label;

  Color get nodeColor => Color(colorHex);

  MindMapNodeModel copyWith({
    String? id,
    String? bookId,
    String? title,
    String? description,
    PlotAct? act,
    String? customActName,
    bool clearCustomActName = false,
    PlotNodeType? type,
    double? dx,
    double? dy,
    List<String>? connectedToIds,
    int? colorHex,
    String? iconEmoji,
    String? linkedChapterId,
    bool clearLinkedChapter = false,
  }) {
    return MindMapNodeModel(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      description: description ?? this.description,
      act: act ?? this.act,
      customActName: clearCustomActName ? null : (customActName ?? this.customActName),
      type: type ?? this.type,
      dx: dx ?? this.dx,
      dy: dy ?? this.dy,
      connectedToIds: connectedToIds ?? List<String>.from(this.connectedToIds),
      colorHex: colorHex ?? this.colorHex,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      linkedChapterId: clearLinkedChapter ? null : (linkedChapterId ?? this.linkedChapterId),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'title': title,
      'description': description,
      'act': act.name,
      'customActName': customActName,
      'type': type.name,
      'dx': dx,
      'dy': dy,
      'connectedToIds': connectedToIds,
      'colorHex': colorHex,
      'iconEmoji': iconEmoji,
      'linkedChapterId': linkedChapterId,
    };
  }

  factory MindMapNodeModel.fromMap(Map<String, dynamic> map) {
    return MindMapNodeModel(
      id: map['id'] as String? ?? '',
      bookId: map['bookId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      act: PlotAct.values.firstWhere(
        (a) => a.name == (map['act'] as String? ?? ''),
        orElse: () => PlotAct.act1Exposition,
      ),
      customActName: map['customActName'] as String?,
      type: PlotNodeType.values.firstWhere(
        (t) => t.name == (map['type'] as String? ?? ''),
        orElse: () => PlotNodeType.mainPlot,
      ),
      dx: (map['dx'] as num?)?.toDouble() ?? 0.0,
      dy: (map['dy'] as num?)?.toDouble() ?? 0.0,
      connectedToIds: (map['connectedToIds'] as List<dynamic>?)?.map((c) => c.toString()).toList() ?? [],
      colorHex: map['colorHex'] as int? ?? 0xFF18181B,
      iconEmoji: map['iconEmoji'] as String? ?? '📌',
      linkedChapterId: map['linkedChapterId'] as String?,
    );
  }
}

extension PlotActExtension on PlotAct {
  String get label {
    switch (this) {
      case PlotAct.prologue:
        return 'Prólogo: Introducción';
      case PlotAct.act1Exposition:
        return 'Acto I: Planteamiento';
      case PlotAct.act2RisingAction:
        return 'Acto II: Nudo y Complicaciones';
      case PlotAct.midpoint:
        return 'Punto Medio';
      case PlotAct.act3Climax:
        return 'Acto III: Clímax';
      case PlotAct.act4Fallout:
        return 'Acto IV: Revelación y Caída';
      case PlotAct.act5Resolution:
        return 'Acto V: Desenlace Final';
      case PlotAct.resolution:
        return 'Resolución';
      case PlotAct.epilogue:
        return 'Epílogo: Conclusión';
      case PlotAct.custom:
        return 'Acto Personalizado';
    }
  }

  String get shortLabel {
    switch (this) {
      case PlotAct.prologue:
        return 'Prólogo';
      case PlotAct.act1Exposition:
        return 'Acto I';
      case PlotAct.act2RisingAction:
        return 'Acto II';
      case PlotAct.midpoint:
        return 'Punto Medio';
      case PlotAct.act3Climax:
        return 'Acto III';
      case PlotAct.act4Fallout:
        return 'Acto IV';
      case PlotAct.act5Resolution:
        return 'Acto V';
      case PlotAct.resolution:
        return 'Resolución';
      case PlotAct.epilogue:
        return 'Epílogo';
      case PlotAct.custom:
        return 'Especial';
    }
  }

  String get defaultEmoji {
    switch (this) {
      case PlotAct.prologue:
        return '📜';
      case PlotAct.act1Exposition:
        return '📖';
      case PlotAct.act2RisingAction:
        return '⚡';
      case PlotAct.midpoint:
        return '🔄';
      case PlotAct.act3Climax:
        return '🔥';
      case PlotAct.act4Fallout:
        return '🌪️';
      case PlotAct.act5Resolution:
        return '🏆';
      case PlotAct.resolution:
        return '✨';
      case PlotAct.epilogue:
        return '🕊️';
      case PlotAct.custom:
        return '🎭';
    }
  }
}

extension PlotNodeTypeExtension on PlotNodeType {
  String get label {
    switch (this) {
      case PlotNodeType.mainPlot:
        return 'Trama Principal';
      case PlotNodeType.subplot:
        return 'Subtrama';
      case PlotNodeType.characterArc:
        return 'Arco de Personaje';
      case PlotNodeType.worldLore:
        return 'Códice / Lore';
      case PlotNodeType.turningPoint:
        return 'Punto de Giro';
    }
  }
}

class TimelineActItem {
  final PlotAct act;
  final String? customName;

  const TimelineActItem(this.act, [this.customName]);

  String get label {
    if (act == PlotAct.custom && customName != null && customName!.trim().isNotEmpty) {
      return customName!.trim();
    }
    return act.label;
  }

  String get shortLabel {
    if (act == PlotAct.custom && customName != null && customName!.trim().isNotEmpty) {
      return customName!.trim();
    }
    return act.shortLabel;
  }

  String get emoji {
    if (act == PlotAct.custom) {
      return '🎭';
    }
    return act.defaultEmoji;
  }

  String get id {
    if (act == PlotAct.custom) {
      return 'custom:${customName ?? 'Personalizado'}';
    }
    return act.name;
  }

  int get orderWeight {
    switch (act) {
      case PlotAct.prologue:
        return 0;
      case PlotAct.act1Exposition:
        return 10;
      case PlotAct.act2RisingAction:
        return 20;
      case PlotAct.midpoint:
        return 30;
      case PlotAct.act3Climax:
        return 40;
      case PlotAct.act4Fallout:
        return 50;
      case PlotAct.act5Resolution:
      case PlotAct.resolution:
        return 60;
      case PlotAct.epilogue:
        return 70;
      case PlotAct.custom:
        return 80;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelineActItem &&
          runtimeType == other.runtimeType &&
          act == other.act &&
          (customName ?? '').trim() == (other.customName ?? '').trim();

  @override
  int get hashCode => act.hashCode ^ ((customName ?? '').trim().hashCode);
}
