import 'package:flutter/material.dart';

class GameConstants {
  // Player
  static const double playerRadius = 10.0;
  static const double playerTrailLength = 25;

  // Planet
  static const double planetMinRadius = 18.0;
  static const double planetMaxRadius = 30.0;
  static const double orbitMinRadius = 70.0;
  static const double orbitMaxRadius = 100.0;

  // Capture radius — how close player must get to snap into orbit
  static const double captureRadiusExtra = 28.0;

  // Launch speed range (pixels/second)
  static const double minLaunchSpeed = 180.0;
  static const double maxLaunchSpeed = 480.0;

  // Power bar
  static const double powerBarCyclesPerSecond = 0.9; // oscillation speed

  // Level spacing
  static const double basePlanetSpacing = 320.0;
  static const double spacingIncreasePerLevel = 15.0;
  static const double maxPlanetSpacing = 550.0;

  // Difficulty thresholds (orbit number)
  static const int obstacleStartOrbit = 2;
  static const int blackHoleStartOrbit = 5;
  static const int multiObstacleStartOrbit = 7;

  // Obstacle
  static const double obstacleRadius = 10.0;
  static const double obstacleOrbitSpeedMin = 0.8;
  static const double obstacleOrbitSpeedMax = 2.2;

  // Black hole
  static const double blackHoleRadius = 22.0;
  static const double blackHoleGravityRadius = 120.0;
  static const double blackHoleGravityStrength = 220.0;
  static const double blackHoleDestroyRadius = 28.0;

  // Colors
  static const Color bgColor = Color(0xFF060612);
  static const Color playerColor = Color(0xFF00E5FF);
  static const Color orbitRingColor = Color(0x2AFFFFFF);

  static const List<Color> planetColors = [
    Color(0xFF7C4DFF),
    Color(0xFF536DFE),
    Color(0xFF00BCD4),
    Color(0xFF1DE9B6),
    Color(0xFFFF6D00),
    Color(0xFFE040FB),
    Color(0xFFFF5252),
    Color(0xFF69F0AE),
  ];

  // Scoring
  static const int pointsPerOrbit = 100;
}
