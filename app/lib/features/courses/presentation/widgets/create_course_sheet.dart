import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/labeled_field.dart';
import '../../../../core/widgets/primary_button.dart';

/// Feuille « Nouveau cours » : renvoie le nom et le niveau saisis.
/// La validation métier est faite par le CoursesBloc puis par le serveur.
Future<({String name, String level})?> showCreateCourseSheet(BuildContext context) {
  return showModalBottomSheet<({String name, String level})>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    builder: (context) => const _CreateCourseForm(),
  );
}

class _CreateCourseForm extends StatefulWidget {
  const _CreateCourseForm();

  @override
  State<_CreateCourseForm> createState() => _CreateCourseFormState();
}

class _CreateCourseFormState extends State<_CreateCourseForm> {
  final _name = TextEditingController();
  final _level = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _level.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Nouveau cours', style: AppText.bold(19)),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Nom du cours',
            hint: 'Développement mobile',
            controller: _name,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          LabeledField(label: 'Niveau', hint: 'L3', controller: _level, textInputAction: TextInputAction.done),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Créer le cours',
            trailingIcon: null,
            onPressed: () => Navigator.pop(context, (name: _name.text, level: _level.text)),
          ),
        ],
      ),
    );
  }
}
