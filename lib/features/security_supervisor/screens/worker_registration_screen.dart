import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/themes.dart';
import '../../../providers/registration_form_provider.dart';
import 'steps/step1_personal_info.dart';
import 'steps/step2_employment_info.dart';
import 'steps/step3_police_verification.dart';

class WorkerRegistrationScreen extends ConsumerWidget {
  const WorkerRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(registrationFormProvider);
    final notifier = ref.read(registrationFormProvider.notifier);

    final steps = ['Personal Info', 'Employment', 'Police Verification'];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Register Worker'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Discard Registration?'),
                content: const Text('All entered data will be lost.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      notifier.reset();
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    child: const Text('Discard',
                        style: TextStyle(color: AppTheme.errorColor)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          // Step indicator
          Container(
            color: AppTheme.primaryColor,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: List.generate(steps.length, (index) {
                final isActive = index == formState.currentStep;
                final isCompleted = index < formState.currentStep;
                return Expanded(
                  child: Row(
                    children: [
                      if (index > 0)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isCompleted
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted
                                  ? Colors.white
                                  : isActive
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.3),
                            ),
                            child: Center(
                              child: isCompleted
                                  ? Icon(Icons.check,
                                      size: 18, color: AppTheme.primaryColor)
                                  : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isActive
                                            ? AppTheme.primaryColor
                                            : Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            steps[index],
                            style: TextStyle(
                              fontSize: 10,
                              color: isActive || isCompleted
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.6),
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      if (index < steps.length - 1) const Expanded(child: SizedBox()),
                    ],
                  ),
                );
              }),
            ),
          ),

          // Error banner
          if (formState.errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppTheme.errorColor.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppTheme.errorColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      formState.errorMessage!,
                      style: const TextStyle(
                          color: AppTheme.errorColor, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // Step content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: switch (formState.currentStep) {
                0 => const Step1PersonalInfo(key: ValueKey('step1')),
                1 => const Step2EmploymentInfo(key: ValueKey('step2')),
                2 => const Step3PoliceVerification(key: ValueKey('step3')),
                _ => const SizedBox.shrink(),
              },
            ),
          ),
        ],
      ),
    );
  }
}
