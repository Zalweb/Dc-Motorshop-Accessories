import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// At or below this quantity stock is "critical".
const criticalStockThreshold = 5;

/// At or below this quantity stock is "low".
const lowStockThreshold = 20;

/// Stock warning label (caps) + color for a given quantity.
/// Critical (≤5) is red, low (≤20) is yellow/amber, otherwise in stock is green.
({String label, Color color}) stockHealth(int qty) {
  if (qty <= criticalStockThreshold) {
    return (label: 'CRITICAL', color: AppColors.danger);
  }
  if (qty <= lowStockThreshold) {
    return (label: 'LOW STOCK', color: AppColors.expense);
  }
  return (label: 'IN STOCK', color: AppColors.active);
}
