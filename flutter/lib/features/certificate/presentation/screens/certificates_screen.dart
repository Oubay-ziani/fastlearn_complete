import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/domain/entities.dart';

// ═══════════════════════════════════════════════════════════
// CERTIFICATES SCREEN
// Student.downloadCertificate() + Certificate.download()
// Enrollment.generateCertificate()
// ═══════════════════════════════════════════════════════════
class CertificatesScreen extends ConsumerStatefulWidget {
  const CertificatesScreen({super.key});
  @override
  ConsumerState<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends ConsumerState<CertificatesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = ref.read(authViewModelProvider).uid;
      if (uid != null) ref.read(certificateViewModelProvider).loadCertificates(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm   = ref.watch(certificateViewModelProvider);
    final auth = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('My Certificates'),
        backgroundColor: Colors.white,
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.certificates.isEmpty
              ? _EmptyState(userId: auth.uid ?? '')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vm.certificates.length,
                  itemBuilder: (_, i) => _CertCard(cert: vm.certificates[i]),
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String userId;
  const _EmptyState({required this.userId});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 110, height: 110,
          decoration: BoxDecoration(
            color: AppTheme.accent.withOpacity(0.12),
            shape: BoxShape.circle),
          child: const Icon(Icons.card_membership_outlined,
            size: 56, color: AppTheme.accent)),
        const SizedBox(height: 24),
        const Text('No Certificates Yet',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        const Text(
          'Complete a full course to earn your certificate of completion.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textGrey, height: 1.5)),
      ]),
    ),
  );
}

class _CertCard extends ConsumerWidget {
  final CertificateEntity cert;
  const _CertCard({required this.cert});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(certificateViewModelProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withOpacity(0.30),
            blurRadius: 16, offset: const Offset(0, 6))]),
      child: Stack(children: [
        // Decorative circles
        Positioned(right: -20, top: -20,
          child: Container(width: 100, height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              shape: BoxShape.circle))),
        Positioned(right: 20, bottom: -30,
          child: Container(width: 80, height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle))),

        Padding(
          padding: const EdgeInsets.all(22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.emoji_events, color: Colors.amber, size: 28)),
              const SizedBox(width: 12),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Certificate of Completion',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                Text('Fast Learn', style: TextStyle(color: Colors.white,
                  fontSize: 16, fontWeight: FontWeight.w800)),
              ]),
            ]),
            const SizedBox(height: 20),

            const Text('This certifies that', style: TextStyle(color: Colors.white60, fontSize: 11)),
            const SizedBox(height: 4),
            Text(cert.studentName,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('has successfully completed', style: TextStyle(color: Colors.white60, fontSize: 11)),
            const SizedBox(height: 4),
            Text(cert.courseName,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
              maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),

            Row(children: [
              const Icon(Icons.calendar_today, size: 13, color: Colors.white54),
              const SizedBox(width: 6),
              Text(
                'Issued: ${cert.issuedDate.toLocal().toString().substring(0, 10)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const Spacer(),
            
                icon: vm.isLoading
                    ? const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download, size: 16),
                label: const Text('Download'),
                onPressed: vm.isLoading ? null : () async {
                  await ref.read(certificateViewModelProvider).downloadCertificate(cert);
                  if (context.mounted && ref.read(certificateViewModelProvider).error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ref.read(certificateViewModelProvider).error!),
                      backgroundColor: AppTheme.error));
                  }
                },
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}
