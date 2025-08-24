import 'package:agritech/main.dart';
import 'package:flutter/material.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () => AppState.of(context)?.setLocale(const Locale('en')),
          child: const Text('English', style: TextStyle(color: Colors.white)),
        ),
        const Text('|', style: TextStyle(color: Colors.white)),
        TextButton(
          onPressed: () => AppState.of(context)?.setLocale(const Locale('bn')),
          child: const Text('বাংলা', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}