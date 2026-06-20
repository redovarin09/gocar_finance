import 'package:flutter/material.dart';
import '../../../core/constants/app_text_styles.dart';

class InsentifScreen extends StatelessWidget {
  const InsentifScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insentif')),
      body: const Center(
        child: Text('Tracker Insentif — Coming soon', style: AppTextStyles.bodySecondary),
      ),
    );
  }
}
