import 'package:flutter/material.dart';

import '../../application/experience_controller.dart';
import '../../app/theme.dart';
import '../../domain/experience_event.dart';
import '../../domain/session_summary.dart';
import 'scene_renderer.dart';

/// Renders the SURVEY state — 5-question post-experience form (Project.md §9).
///
/// Questions:
/// 1. "你认为刚才体验的是什么？" — multiline text
/// 2. "哪一刻最吸引你？" — multiline text
/// 3. "哪一刻最难理解或开始走神？" — multiline text
/// 4. "是否愿意体验30-45分钟完整版？" — Yes/No toggle
/// 5. "是否愿意参加下一轮测试？" — Yes/No toggle
class SurveyRenderer implements SceneRenderer {
  final void Function(ExperienceEvent) onEvent;

  const SurveyRenderer({required this.onEvent});

  @override
  Widget build(BuildContext context, SceneViewModel viewModel) {
    return _SurveyForm(onSubmit: (answers) {
      onEvent(SubmitSurvey(answers));
    });
  }
}

class _SurveyForm extends StatefulWidget {
  final ValueChanged<SurveyAnswers> onSubmit;
  const _SurveyForm({required this.onSubmit});

  @override
  State<_SurveyForm> createState() => _SurveyFormState();
}

class _SurveyFormState extends State<_SurveyForm> {
  final _q1Controller = TextEditingController();
  final _q2Controller = TextEditingController();
  final _q3Controller = TextEditingController();
  bool _q4Answer = false;
  bool _q5Answer = false;

  @override
  void dispose() {
    _q1Controller.dispose();
    _q2Controller.dispose();
    _q3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '体验问卷',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '请根据您的真实感受回答以下问题',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 32),

            // Q1
            _QuestionLabel(number: 1, text: '你认为刚才体验的是什么？'),
            const SizedBox(height: 10),
            TextField(
              controller: _q1Controller,
              maxLines: 3,
              style: theme.textTheme.bodyMedium,
              decoration: _inputDecoration('请描述您的理解...'),
            ),
            const SizedBox(height: 24),

            // Q2
            _QuestionLabel(number: 2, text: '哪一刻最吸引你？'),
            const SizedBox(height: 10),
            TextField(
              controller: _q2Controller,
              maxLines: 3,
              style: theme.textTheme.bodyMedium,
              decoration: _inputDecoration('请描述最吸引你的时刻...'),
            ),
            const SizedBox(height: 24),

            // Q3
            _QuestionLabel(number: 3, text: '哪一刻最难理解或开始走神？'),
            const SizedBox(height: 10),
            TextField(
              controller: _q3Controller,
              maxLines: 3,
              style: theme.textTheme.bodyMedium,
              decoration: _inputDecoration('请描述感到困惑或走神的时刻...'),
            ),
            const SizedBox(height: 24),

            // Q4: Yes/No toggle
            _QuestionLabel(number: 4, text: '是否愿意体验30-45分钟完整版？'),
            const SizedBox(height: 10),
            _YesNoToggle(value: _q4Answer, onChanged: (v) {
              setState(() => _q4Answer = v);
            }),
            const SizedBox(height: 24),

            // Q5: Yes/No toggle
            _QuestionLabel(number: 5, text: '是否愿意参加下一轮测试？'),
            const SizedBox(height: 10),
            _YesNoToggle(value: _q5Answer, onChanged: (v) {
              setState(() => _q5Answer = v);
            }),
            const SizedBox(height: 40),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSubmit(
                    SurveyAnswers(
                      experienceDescription: _q1Controller.text.trim(),
                      mostEngagingMoment: _q2Controller.text.trim(),
                      confusingMoment: _q3Controller.text.trim(),
                      wantsLongerExperience: _q4Answer,
                      wantsNextTest: _q5Answer,
                    ),
                  );
                },
                child: const Text('提交问卷'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textDisabled.withOpacity(0.6)),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 1),
      ),
      contentPadding: const EdgeInsets.all(14),
    );
  }
}

class _QuestionLabel extends StatelessWidget {
  final int number;
  final String text;
  const _QuestionLabel({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

class _YesNoToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _YesNoToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: _ToggleButton(
            label: '是',
            selected: value,
            onTap: () => onChanged(true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ToggleButton(
            label: '否',
            selected: !value,
            onTap: () => onChanged(false),
          ),
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primaryLight : AppColors.divider,
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
