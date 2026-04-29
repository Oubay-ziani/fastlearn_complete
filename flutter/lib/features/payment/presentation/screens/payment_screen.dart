import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/domain/entities.dart';

// ═══════════════════════════════════════════════════════════
// PAYMENT SCREEN — Student.buyCourse + Payment.process()
// Integrates with PaymentViewModel
// Shows card form, processes payment, enrolls on success
// ═══════════════════════════════════════════════════════════
class PaymentScreen extends ConsumerStatefulWidget {
  final String courseId;
  const PaymentScreen({super.key, required this.courseId});
  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _cardCtrl  = TextEditingController(text: '4242 4242 4242 4242');
  final _expiryCtrl= TextEditingController(text: '12/26');
  final _cvvCtrl   = TextEditingController(text: '123');
  final _nameCtrl  = TextEditingController();
  bool  _saveCard  = false;
  CourseEntity? _course;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(courseViewModelProvider).selectCourse(widget.courseId);
      setState(() => _course = ref.read(courseViewModelProvider).selectedCourse);
      final user = ref.read(authViewModelProvider).user;
      _nameCtrl.text = user?.name ?? '';
    });
  }

  @override
  void dispose() {
    _cardCtrl.dispose(); _expiryCtrl.dispose();
    _cvvCtrl.dispose(); _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_course == null) return;

    final authVM    = ref.read(authViewModelProvider);
    final payVM     = ref.read(paymentViewModelProvider);
    final courseVM  = ref.read(courseViewModelProvider);

    if (authVM.uid == null) { context.go('/auth/login'); return; }

    // Process payment
    final success = await payVM.processCoursePayment(
      userId: authVM.uid!,
      courseId: widget.courseId,
      amount: _course!.price,
    );

    if (!mounted) return;
    if (success) {
      // Enroll user after successful payment
      await courseVM.enrollInCourse(authVM.uid!, widget.courseId);
      if (!mounted) return;
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(payVM.error ?? 'Payment failed. Please try again.'),
        backgroundColor: AppTheme.error));
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(
              color: AppTheme.success, shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.white, size: 44)),
          const SizedBox(height: 20),
          const Text('Payment Successful!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('You\'re now enrolled in\n"${_course!.title}"',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/course/${widget.courseId}');
            },
            child: const Text('Start Learning'),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payVM = ref.watch(paymentViewModelProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: _course == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // ── Order Summary ──
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Order Summary',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 14),
                      Row(children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
                            borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.school, color: Colors.white, size: 30)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_course!.title,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text('by ${_course!.teacherName}',
                            style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                        ])),
                      ]),
                      const Divider(height: 24),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Course Price:', style: TextStyle(color: AppTheme.textGrey)),
                        Text('\$${_course!.price.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 8),
                      const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Platform Fee:', style: TextStyle(color: AppTheme.textGrey)),
                        Text('\$0.00', style: TextStyle(fontWeight: FontWeight.w600)),
                      ]),
                      const Divider(height: 20),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Total:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('\$${_course!.price.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTheme.primary)),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // ── Payment Method ──
                  const Text('Payment Details',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text('Secured by Stripe • Test mode',
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                    child: Column(children: [
                      // Card number
                      TextFormField(
                        controller: _cardCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 19,
                        decoration: const InputDecoration(
                          labelText: 'Card Number',
                          prefixIcon: Icon(Icons.credit_card, color: AppTheme.primary),
                          counterText: '',
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Card number required';
                          if (v.replaceAll(' ', '').length < 16) return 'Enter 16-digit card number';
                          return null;
                        },
                        onChanged: (v) {
                          // Format card number with spaces
                          final digits = v.replaceAll(' ', '');
                          if (digits.length <= 16) {
                            final formatted = digits.replaceAllMapped(
                              RegExp(r'.{1,4}'), (m) => '${m.group(0)} ').trim();
                            if (formatted != v) {
                              _cardCtrl.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(offset: formatted.length));
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      // Cardholder name
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Cardholder Name',
                          prefixIcon: Icon(Icons.person_outline, color: AppTheme.primary)),
                        validator: (v) => v == null || v.isEmpty ? 'Name required' : null,
                      ),
                      const SizedBox(height: 14),
                      // Expiry + CVV
                      Row(children: [
                        Expanded(child: TextFormField(
                          controller: _expiryCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'MM/YY',
                            prefixIcon: Icon(Icons.date_range_outlined, color: AppTheme.primary)),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        )),
                        const SizedBox(width: 14),
                        Expanded(child: TextFormField(
                          controller: _cvvCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 3,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'CVV',
                            prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primary),
                            counterText: ''),
                          validator: (v) => v == null || v.length < 3 ? 'Required' : null,
                        )),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Checkbox(
                          value: _saveCard,
                          onChanged: (v) => setState(() => _saveCard = v ?? false),
                          activeColor: AppTheme.primary),
                        const Text('Save card for future purchases',
                          style: TextStyle(fontSize: 13, color: AppTheme.textGrey)),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 12),

                  // Security badges
                  const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.lock, size: 14, color: AppTheme.textGrey),
                    SizedBox(width: 6),
                    Text('256-bit SSL encryption  •  Secure checkout',
                      style: TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                  ]),
                  const SizedBox(height: 24),

                  // Pay button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: payVM.isLoading ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.success),
                      child: payVM.isLoading
                          ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                              SizedBox(width: 12),
                              Text('Processing payment...', style: TextStyle(color: Colors.white)),
                            ])
                          : Text('Pay \$${_course!.price.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(child: Text('By completing purchase you agree to our Terms of Service',
                    style: TextStyle(fontSize: 11, color: AppTheme.textGrey),
                    textAlign: TextAlign.center)),
                ]),
              ),
            ),
    );
  }
}
