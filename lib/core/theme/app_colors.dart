import 'package:flutter/material.dart';

/// Design tokens for DC Motorcycle Inventory.
/// Source of truth: AGENT.md → Design System → Colors.
abstract final class AppColors {
  // Backgrounds - premium midnight slate-navy theme (Dark Mode)
  static const bgBase = Color(0xFF0C101B);
  static const bgSurface = Color(0xFF151C2C);
  static const bgSurface2 = Color(0xFF1E293B);
  static const border = Color(0xFF222F47);

  // Backgrounds - clean off-white theme (Light Mode)
  static const bgBaseLight = Color(0xFFFAFAFA);
  static const bgSurfaceLight = Color(0xFFFFFFFF);
  static const bgSurface2Light = Color(0xFFF7F7F7);
  static const borderLight = Color(0xFFE5E7EB);

  // Accent (Default blue, but now we'll support dynamic overrides)
  static const accent = Color(0xFF3B82F6);
  static const accentLight = Color(0xFF60A5FA);

  // Text (Dark Mode)
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textMuted = Color(0xFF64748B);

  // Text (Light Mode)
  static const textPrimaryLight = Colors.black;
  static const textSecondaryLight = Color(0xFF4B5563);
  static const textMutedLight = Color(0xFF9CA3AF);

  // Status colors (dashboard metric cards)
  static const profit = Color(0xFF38BDF8);
  static const cogs = Color(0xFF34D399);
  static const expense = Color(0xFFF59E0B);
  static const discount = Color(0xFFA78BFA);
  static const margin = Color(0xFF60A5FA);
  static const active = Color(0xFF4ADE80);

  // Danger
  static const danger = Color(0xFFF87171);
}


