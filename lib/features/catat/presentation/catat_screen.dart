import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class CatatScreen extends StatelessWidget {
  const CatatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Catat'),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(icon: Icon(Icons.add_circle_outline_rounded), text: 'Pemasukan'),
              Tab(icon: Icon(Icons.remove_circle_outline_rounded), text: 'Pengeluaran'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Center(child: Text('Form Trip — Coming soon', style: AppTextStyles.bodySecondary)),
            Center(child: Text('Form Pengeluaran — Coming soon', style: AppTextStyles.bodySecondary)),
          ],
        ),
      ),
    );
  }
}
