import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Admin panelde metin olarak girilen Material Symbols adlarını ikona çevirir.
IconData iconFromName(String? name) => switch (name) {
      'restaurant' => Symbols.restaurant,
      'flight_takeoff' => Symbols.flight_takeoff,
      'work' => Symbols.work,
      'summarize' => Symbols.summarize,
      'forum' => Symbols.forum,
      'school' => Symbols.school,
      'local_fire_department' => Symbols.local_fire_department,
      'bolt' => Symbols.bolt,
      'menu_book' => Symbols.menu_book,
      'military_tech' => Symbols.military_tech,
      'shopping_cart' => Symbols.shopping_cart,
      'hotel' => Symbols.hotel,
      'local_hospital' => Symbols.local_hospital,
      'coffee' => Symbols.coffee,
      'directions' => Symbols.directions,
      'phone_in_talk' => Symbols.phone_in_talk,
      _ => Symbols.chat,
    };

IconData skillIcon(String skill) => switch (skill) {
      'listening' => Symbols.headphones,
      'speaking' => Symbols.record_voice_over,
      'grammar' => Symbols.spellcheck,
      _ => Symbols.menu_book,
    };

String skillLabel(String skill) => switch (skill) {
      'listening' => 'Dinleme',
      'speaking' => 'Konuşma',
      'grammar' => 'Dil Bilgisi',
      _ => 'Kelime',
    };
