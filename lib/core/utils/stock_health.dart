import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// At or below this quantity stock is "critical" (red).
const criticalStockThreshold = 2;

/// At or below this quantity stock is "low" (yellow/amber warning).
const lowStockThreshold = 5;

/// Returns true if the quantity is in the red critical zone (<= 2).
bool isStockRed(int qty) => qty <= criticalStockThreshold;

/// Stock warning label (caps) + color for a given quantity.
/// Critical (≤2) is red, low (3–5) is yellow/amber, otherwise in stock (>5) is green.
({String label, Color color}) stockHealth(int qty) {
  if (qty <= criticalStockThreshold) {
    return (label: 'CRITICAL', color: AppColors.danger);
  }
  if (qty <= lowStockThreshold) {
    return (label: 'LOW STOCK', color: AppColors.expense);
  }
  return (label: 'IN STOCK', color: AppColors.active);
}
