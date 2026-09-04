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
  double dx;
  double dy;
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

  String get actLabel {
    switch (act) {
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

  String get typeLabel {
    switch (type) {
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
      connectedToIds: connectedToIds ?? List.from(this.connectedToIds),
      colorHex: colorHex ?? this.colorHex,
      iconEmoji: iconEmoji ?? this.iconEmoji,
    );
  }
}
