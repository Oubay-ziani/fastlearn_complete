import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/domain/entities.dart';
import '../../../../core/constants/app_constants.dart';

// ═══════════════════════════════════════════════════════════
// SESSIONS SCREEN — Student.reserveSession + Session.cancel
// ═══════════════════════════════════════════════════════════
class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});
  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = ref.read(authViewModelProvider).uid;
      if (uid != null) {
        ref.read(sessionViewModelProvider).watchStudentSessions(uid);
      }
    });
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(sessionViewModelProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('My Sessions'),
        backgroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textGrey,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'My Bookings'),
            Tab(text: 'Available'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/sessions/book'),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Book Session', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // My bookings
          vm.sessions.isEmpty
              ? const _EmptySessionState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vm.sessions.length,
                  itemBuilder: (_, i) => _MySessionCard(session: vm.sessions[i]),
                ),
          // Available sessions browser
          const _AvailableSessionsTab(),
        ],
      ),
    );
  }
}

class _EmptySessionState extends StatelessWidget {
  const _EmptySessionState();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.08), shape: BoxShape.circle),
        child: const Icon(Icons.video_call_outlined, size: 50, color: AppTheme.primary)),
      const SizedBox(height: 20),
      const Text('No Sessions Booked', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const Text('Book a 1-on-1 session with an instructor',
        style: TextStyle(color: AppTheme.textGrey), textAlign: TextAlign.center),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        icon: const Icon(Icons.search),
        label: const Text('Browse Sessions'),
        onPressed: () {},
      ),
    ]),
  );
}

class _MySessionCard extends ConsumerWidget {
  final SessionEntity session;
  const _MySessionCard({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid  = ref.read(authViewModelProvider).uid ?? '';
    final vm   = ref.read(sessionViewModelProvider);
    final isPast = session.scheduledAt.isBefore(DateTime.now());

    Color statusColor = switch (session.status) {
      AppConstants.sessionScheduled => AppTheme.success,
      AppConstants.sessionCancelled => AppTheme.error,
      _ => AppTheme.textGrey,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.video_call, color: AppTheme.accent, size: 28)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                '${session.scheduledAt.day}/${session.scheduledAt.month}/${session.scheduledAt.year} '
                'at ${session.scheduledAt.hour.toString().padLeft(2,'0')}:${session.scheduledAt.minute.toString().padLeft(2,'0')}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 4),
              Text('${session.durationMinutes} minutes  •  \$${session.price.toStringAsFixed(0)}',
                style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
              child: Text(session.status.toUpperCase(),
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700))),
          ]),

          if (!isPast && session.status == AppConstants.sessionScheduled) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.cancel_outlined, size: 16, color: AppTheme.error),
                label: const Text('Cancel', style: TextStyle(color: AppTheme.error, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.error),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                onPressed: () async {
                  final ok = await vm.cancelSession(session.sessionId, uid);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok ? 'Session cancelled' : 'Could not cancel'),
                      backgroundColor: ok ? AppTheme.warning : AppTheme.error));
                  }
                },
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}

// ── Available Sessions Tab ──
class _AvailableSessionsTab extends ConsumerStatefulWidget {
  const _AvailableSessionsTab();
  @override
  ConsumerState<_AvailableSessionsTab> createState() => _AvailableSessionsTabState();
}

class _AvailableSessionsTabState extends ConsumerState<_AvailableSessionsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
      ref.read(sessionViewModelProvider).watchAvailableSessions());
  }

  @override
  Widget build(BuildContext context) {
    final vm  = ref.watch(sessionViewModelProvider);
    final uid = ref.read(authViewModelProvider).uid ?? '';

    if (vm.sessions.isEmpty) {
      return const Center(child: Text('No available sessions right now',
        style: TextStyle(color: AppTheme.textGrey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vm.sessions.length,
      itemBuilder: (_, i) {
        final s = vm.sessions[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
          child: Row(children: [
            const Icon(Icons.calendar_month, color: AppTheme.primary, size: 36),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                '${s.scheduledAt.day}/${s.scheduledAt.month}/${s.scheduledAt.year} '
                '${s.scheduledAt.hour.toString().padLeft(2,'0')}:${s.scheduledAt.minute.toString().padLeft(2,'0')}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              Text('${s.durationMinutes} min', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('\$${s.price.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.primary)),
              const SizedBox(height: 4),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                onPressed: uid.isEmpty ? null : () async {
                  // Reserve + payment flow
                  final reserved = await vm.reserveSession(
                    sessionId: s.sessionId, studentId: uid);
                  if (context.mounted) {
                    if (reserved) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Session booked! 🎉'), backgroundColor: AppTheme.success));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(vm.error ?? 'Could not book session'),
                        backgroundColor: AppTheme.error));
                    }
                  }
                },
                child: const Text('Book Now'),
              ),
            ]),
          ]),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// BOOK SESSION SCREEN
// ═══════════════════════════════════════════════════════════
class BookSessionScreen extends ConsumerWidget {
  const BookSessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Book a Session'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Browse available sessions below, or go back to see all.',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('View Available Sessions'),
          ),
        ]),
      ),
    );
  }
}
