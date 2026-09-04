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
        return 'Act I: Setup & Inciting Incident';
      case PlotAct.act2RisingAction:
        return 'Act II: Rising Action & Complications';
      case PlotAct.midpoint:
        return 'Midpoint Turning Point';
      case PlotAct.act3Climax:
        return 'Act III: Climax';
      case PlotAct.resolution:
        return 'Resolution & Aftermath';
    }
  }

  String get typeLabel {
    switch (type) {
      case PlotNodeType.mainPlot:
        return 'Main Plot';
      case PlotNodeType.subplot:
        return 'Subplot';
      case PlotNodeType.characterArc:
        return 'Character Arc';
      case PlotNodeType.worldLore:
        return 'World Lore';
      case PlotNodeType.turningPoint:
        return 'Turning Point';
    }
  }

  Color get nodeColor => Color(colorHex);
}
