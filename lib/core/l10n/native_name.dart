import 'dart:ui' show Locale;

String nativeNameFor(Locale locale) => switch (locale.languageCode) {
      'en' => 'English',
      'es' => 'Español',
      _ => locale.languageCode,
    };
