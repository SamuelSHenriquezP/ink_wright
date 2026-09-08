import 'package:flutter/material.dart';

enum PlotAct {
  act1Exposition,
  act2RisingAction,
  midpoint,
  act3Climax,
  resolution,
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
  final PlotNodeType type;
  final double dx;
  final double dy;
  final List<String> connectedToIds;
  final int colorHex;
  final String iconEmoji;

  MindMapNodeModel({
    required this.id,
    required this.bookId,
    required this.title,
    required this.description,
    required this.act,
    required this.type,
    required this.dx,
    required this.dy,
    required this.connectedToIds,
    required this.colorHex,
    required this.iconEmoji,
  });

  String get actLabel => act.label;
  String get typeLabel => type.label;

  Color get nodeColor => Color(colorHex);

  MindMapNodeModel copyWith({
    String? id,
    String? bookId,
    String? title,
    String? description,
    PlotAct? act,
    PlotNodeType? type,
    double? dx,
    double? dy,
    List<String>? connectedToIds,
    int? colorHex,
    String? iconEmoji,
  }) {
    return MindMapNodeModel(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      description: description ?? this.description,
      act: act ?? this.act,
      type: type ?? this.type,
      dx: dx ?? this.dx,
      dy: dy ?? this.dy,
      connectedToIds: connectedToIds ?? List<String>.from(this.connectedToIds),
      colorHex: colorHex ?? this.colorHex,
      iconEmoji: iconEmoji ?? this.iconEmoji,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'title': title,
      'description': description,
      'act': act.name,
      'type': type.name,
      'dx': dx,
      'dy': dy,
      'connectedToIds': connectedToIds,
      'colorHex': colorHex,
      'iconEmoji': iconEmoji,
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
      type: PlotNodeType.values.firstWhere(
        (t) => t.name == (map['type'] as String? ?? ''),
        orElse: () => PlotNodeType.mainPlot,
      ),
      dx: (map['dx'] as num?)?.toDouble() ?? 0.0,
      dy: (map['dy'] as num?)?.toDouble() ?? 0.0,
      connectedToIds: (map['connectedToIds'] as List<dynamic>?)?.map((c) => c.toString()).toList() ?? [],
      colorHex: map['colorHex'] as int? ?? 0xFF18181B,
      iconEmoji: map['iconEmoji'] as String? ?? '📌',
    );
  }
}

extension PlotActExtension on PlotAct {
  String get label {
    switch (this) {
      case PlotAct.act1Exposition:
        return 'Acto I: Planteamiento';
      case PlotAct.act2RisingAction:
        return 'Acto II: Nudo y Complicaciones';
      case PlotAct.midpoint:
        return 'Punto Medio';
      case PlotAct.act3Climax:
        return 'Acto III: Clímax';
      case PlotAct.resolution:
        return 'Resolución';
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
