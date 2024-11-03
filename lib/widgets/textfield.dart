import 'package:flutter/material.dart';

InputDecoration customInputDecoration(String label, [IconData? icon]) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.grey), // İlk durumda gri
    floatingLabelStyle: const TextStyle(color: Colors.black), // Üste çıkarken siyah
    filled: true,
    fillColor: Colors.grey[100],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.black),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.black),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.black, width: 1.5),
    ),
    prefixIcon: icon != null ? Icon(icon) : null, // İkon varsa göster, yoksa null
  );
}

