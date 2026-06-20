import 'package:flutter/material.dart';
import '../../../core/constants/app_text_styles.dart';

class LaporanScreen extends StatelessWidget {
  const LaporanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan')),
      body: const Center(
        child: Text('Laporan Keuangan — Coming soon', style: AppTextStyles.bodySecondary),
      ),
    );
  }
}
