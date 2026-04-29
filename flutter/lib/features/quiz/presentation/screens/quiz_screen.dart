import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════
// QUIZ SCREEN — Student.takeExam + submitAnswers
// Exam.autoGrade + ExamResult.viewResult
// ═══════════════════════════════════════════════════════════
class QuizScreen extends ConsumerStatefulWidget {
  final String courseId, examId;
  const QuizScreen({super.key, required this.courseId, required this.examId});
  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _currentQuestion = 0;
  final _pageCtrl = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizViewModelProvider).loadExam(widget.courseId, widget.examId);
    });
  }

  @override
  void dispose() { _pageCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final userId = ref.read(authViewModelProvider).uid ?? '';
    final result = await ref.read(quizViewModelProvider).submitAnswers(
      userId: userId,
      courseId: widget.courseId,
      examId: widget.examId,
    );
    if (!mounted) return;
    if (result != null) {
      context.push('/course/${widget.courseId}/quiz/${widget.examId}/results');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit. Please try again.'),
          backgroundColor: AppTheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(quizViewModelProvider);

    if (vm.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (vm.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(vm.currentExam?.title ?? 'Quiz')),
        body: const Center(child: Text('No questions in this quiz yet.')));
    }

    final q = vm.questions[_currentQuestion];
    final progress = (_currentQuestion + 1) / vm.questions.length;
    final isLast = _currentQuestion == vm.questions.length - 1;
    final answered = vm.answers[q.questionId] != null;
    final allAnswered = vm.questions.every((q) => vm.answers[q.questionId] != null);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(vm.currentExam?.title ?? 'Quiz'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text(
              '${_currentQuestion + 1}/${vm.questions.length}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary))),
          ),
        ],
      ),
      body: Column(children: [
        // Progress bar
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppTheme.divider,
          valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
          minHeight: 4,
        ),

        Expanded(
          child: PageView.builder(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: vm.questions.length,
            itemBuilder: (_, i) {
              final question = vm.questions[i];
              final selected = vm.answers[question.questionId];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 10),

                  // Question number badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                    child: Text('Question ${i + 1} • ${question.marks} pts',
                      style: const TextStyle(
                        color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                  const SizedBox(height: 16),

                  // Question text
                  Text(question.questionText,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.5)),
                  const SizedBox(height: 24),

                  // Options
                  ...question.options.map((opt) {
                    final isSelected = selected == opt;
                    return GestureDetector(
                      onTap: () => ref.read(quizViewModelProvider).selectAnswer(question.questionId, opt),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppTheme.primary : AppTheme.divider,
                            width: isSelected ? 2 : 1),
                          boxShadow: isSelected
                              ? [BoxShadow(color: AppTheme.primary.withOpacity(0.25),
                                  blurRadius: 12, offset: const Offset(0, 4))]
                              : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                        ),
                        child: Row(children: [
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? Colors.white : AppTheme.bg,
                              border: Border.all(
                                color: isSelected ? Colors.white : AppTheme.divider)),
                            child: isSelected
                                ? const Icon(Icons.check, color: AppTheme.primary, size: 16)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Text(opt,
                            style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : AppTheme.textDark))),
                        ]),
                      ),
                    );
                  }),
                ]),
              );
            },
          ),
        ),

        // Navigation buttons
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white, border: Border(top: BorderSide(color: AppTheme.divider))),
          child: Row(children: [
            if (_currentQuestion > 0)
              Expanded(child: OutlinedButton(
                onPressed: () {
                  setState(() => _currentQuestion--);
                  _pageCtrl.previousPage(
                    duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                },
                child: const Text('Previous'),
              )),
            if (_currentQuestion > 0) const SizedBox(width: 12),
            Expanded(child: isLast
                ? ElevatedButton(
                    onPressed: (!allAnswered || vm.isLoading) ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                    child: vm.isLoading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(allAnswered ? 'Submit Quiz' : 'Answer All Questions'),
                  )
                : ElevatedButton(
                    onPressed: answered ? () {
                      setState(() => _currentQuestion++);
                      _pageCtrl.nextPage(
                        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    } : null,
                    child: const Text('Next'),
                  )),
          ]),
        ),
      ]),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Exit Quiz?'),
      content: const Text('Your progress will be lost if you exit now.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () { Navigator.pop(context); context.pop(); },
          child: const Text('Exit', style: TextStyle(color: AppTheme.error))),
      ],
    ));
  }
}

// ═══════════════════════════════════════════════════════════
// QUIZ RESULTS SCREEN — ExamResult.viewResult
// ═══════════════════════════════════════════════════════════
class QuizResultsScreen extends ConsumerWidget {
  final String courseId, examId;
  const QuizResultsScreen({super.key, required this.courseId, required this.examId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(quizViewModelProvider);
    final result = vm.lastResult;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Results')),
        body: const Center(child: Text('No result found.')));
    }

    final pct = result.totalMarks > 0 ? result.score / result.totalMarks : 0.0;
    final passed = result.passed;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Quiz Results'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          // Result header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: passed
                    ? [AppTheme.success, const Color(0xFF27AE60)]
                    : [AppTheme.error, const Color(0xFFC0392B)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Column(children: [
              Icon(passed ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                color: Colors.white, size: 70),
              const SizedBox(height: 16),
              Text(passed ? '🎉 Congratulations!' : 'Keep Practicing!',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(passed ? 'You passed the quiz!' : 'You didn\'t pass this time.',
                style: const TextStyle(color: Colors.white70, fontSize: 15)),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              // Circular progress
              CircularPercentIndicator(
                radius: 90,
                lineWidth: 14,
                percent: pct,
                center: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('${(pct * 100).toInt()}%',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                  const Text('Score', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                ]),
                progressColor: passed ? AppTheme.success : AppTheme.error,
                backgroundColor: AppTheme.divider,
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
                animationDuration: 1000,
              ),
              const SizedBox(height: 28),

              // Stats grid
              Row(children: [
                _ResultStat('Score', '${result.score}/${result.totalMarks}', Icons.grade),
                _ResultStat('Status', passed ? 'PASSED' : 'FAILED', Icons.verified),
                _ResultStat('Questions', '${vm.questions.length}', Icons.quiz),
              ]),
              const SizedBox(height: 28),

              // Correct / Incorrect breakdown
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Answer Breakdown',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 16),
                  ...vm.questions.asMap().entries.map((entry) {
                    final q = entry.value;
                    final userAns = vm.answers[q.questionId] ?? '';
                    final correct = userAns == q.correctAnswer;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: correct
                            ? AppTheme.success.withOpacity(0.08)
                            : AppTheme.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: correct ? AppTheme.success : AppTheme.error, width: 0.8)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(correct ? Icons.check_circle : Icons.cancel,
                            color: correct ? AppTheme.success : AppTheme.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Q${entry.key + 1}: ${q.questionText}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 2, overflow: TextOverflow.ellipsis)),
                        ]),
                        if (!correct) ...[
                          const SizedBox(height: 6),
                          Text('Your answer: $userAns',
                            style: const TextStyle(color: AppTheme.error, fontSize: 12)),
                          Text('Correct: ${q.correctAnswer}',
                            style: const TextStyle(color: AppTheme.success, fontSize: 12)),
                        ],
                      ]),
                    );
                  }),
                ]),
              ),
              const SizedBox(height: 24),

              // Actions
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  onPressed: () {
                    ref.read(quizViewModelProvider).resetQuiz();
                    context.go('/course/$courseId/quiz/$examId');
                  },
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Course'),
                  onPressed: () => context.go('/course/$courseId'),
                )),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _ResultStat(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    margin: const EdgeInsets.symmetric(horizontal: 4),
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
    child: Column(children: [
      Icon(icon, color: AppTheme.primary, size: 22),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 11)),
    ]),
  ));
}
