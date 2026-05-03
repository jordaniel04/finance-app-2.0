import 'package:flutter/material.dart';

const _kFont = 'MaterialIcons';
const _kFallback = 0xe8b6; // search — visible fallback for unknown names

const Map<String, int> kIconCodePoints = {
  // Dinero / finanzas
  'attach_money': 0xe0b2,
  'payments': 0xe482,
  'credit_card': 0xe19f,
  'account_balance': 0xe040,
  'sync_alt': 0xe630,
  'paid': 0xe46a,
  // Hogar / servicios
  'home': 0xe318,
  'water_drop': 0xf05a2,
  'lightbulb': 0xe37b,
  'local_gas_station': 0xe394,
  'wifi': 0xe6e7,
  'smartphone': 0xe5c6,
  // Comida / salud
  'restaurant': 0xe532,
  'local_hospital': 0xe396,
  'healing': 0xe304,
  'psychology': 0xe4ef,
  // Transporte / compras
  'directions_car': 0xe1d7,
  'shopping_cart': 0xe59c,
  'shopping_bag': 0xe59a,
  'checkroom': 0xe15d,
  // Trabajo / educación
  'work': 0xe6f2,
  'book': 0xe0ef,
  'menu_book': 0xe3dd,
  'smart_toy': 0xe5c5,
  // Ocio / social
  'sports_esports': 0xe5e8,
  'celebration': 0xe149,
  'cake': 0xe120,
  'groups': 0xe2ee,
  // Bebé / familia
  'stroller': 0xe612,
  // Fe / extras
  'church': 0xf04cd,
  'favorite': 0xe25b,
  'star': 0xe5f9,
  'card_giftcard': 0xe13e,
};

/// Ordered list of icon names for the picker (defines display order).
const List<String> kIconNames = [
  // Dinero / finanzas
  'attach_money', 'payments', 'credit_card', 'account_balance',
  'sync_alt', 'paid',
  // Hogar / servicios
  'home', 'water_drop', 'lightbulb', 'local_gas_station', 'wifi', 'smartphone',
  // Comida / salud
  'restaurant', 'local_hospital', 'healing', 'psychology',
  // Transporte / compras
  'directions_car', 'shopping_cart', 'shopping_bag', 'checkroom',
  // Trabajo / educación
  'work', 'book', 'menu_book', 'smart_toy',
  // Ocio / social
  'sports_esports', 'celebration', 'cake', 'groups',
  // Bebé / familia
  'stroller',
  // Fe / extras
  'church', 'favorite', 'star', 'card_giftcard',
];

IconData iconDataFromName(String name) {
  final code = kIconCodePoints[name] ?? _kFallback;
  return IconData(code, fontFamily: _kFont);
}
