// ═══════════════════════════════════════════════════════════
// payment_history_screen.dart
// ═══════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key});
  @override
  ConsumerState<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = ref.read(authViewModelProvider).uid;
      if (uid != null) ref.read(paymentViewModelProvider).loadUserPayments(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(paymentViewModelProvider);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Payment History'), backgroundColor: Colors.white),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.payments.isEmpty
              ? const Center(child: Text('No payments yet', style: TextStyle(color: AppTheme.textGrey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vm.payments.length,
                  itemBuilder: (_, i) {
                    final p = vm.payments[i];
                    final success = p.status == AppConstants.paymentSuccess;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: (success ? AppTheme.success : AppTheme.error).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10)),
                          child: Icon(
                            success ? Icons.check_circle_outline : Icons.error_outline,
                            color: success ? AppTheme.success : AppTheme.error)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Course Purchase', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text(p.paidAt.toString().substring(0, 16),
                            style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('\$${p.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (success ? AppTheme.success : AppTheme.error).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6)),
                            child: Text(p.status.toUpperCase(),
                              style: TextStyle(
                                color: success ? AppTheme.success : AppTheme.error,
                                fontSize: 10, fontWeight: FontWeight.w700))),
                        ]),
                      ]),
                    );
                  },
                ),
    );
  }
}
