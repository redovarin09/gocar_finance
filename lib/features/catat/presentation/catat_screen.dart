import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'widgets/form_pemasukan.dart';
import 'widgets/form_pengeluaran.dart';

class CatatScreen extends StatelessWidget {
  const CatatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Catat Transaksi'),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(
                icon: Icon(Icons.add_circle_outline_rounded),
                text: 'Pemasukan',
              ),
              Tab(
                icon: Icon(Icons.remove_circle_outline_rounded),
                text: 'Pengeluaran',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            FormPemasukan(),
            FormPengeluaran(),
          ],
        ),
      ),
    );
  }
}
