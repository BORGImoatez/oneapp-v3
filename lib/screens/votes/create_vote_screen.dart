import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/vote_provider.dart';
import '../../utils/app_theme.dart';
import '../../models/channel_model.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class CreateVoteScreen extends StatefulWidget {
  final Channel channel;

  const CreateVoteScreen({super.key, required this.channel});

  @override
  State<CreateVoteScreen> createState() => _CreateVoteScreenState();
}

class _CreateVoteScreenState extends State<CreateVoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  
  String _voteType = 'SINGLE_CHOICE';
  bool _isAnonymous = false;
  DateTime? _endDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length < 10) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  void _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _endDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _createVote() async {
    if (_formKey.currentState!.validate()) {
      final options = _optionControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      if (options.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Au moins 2 options sont requises'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      final voteProvider = Provider.of<VoteProvider>(context, listen: false);
      
      final voteData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'channelId': widget.channel.id,
        'voteType': _voteType,
        'isAnonymous': _isAnonymous,
        'endDate': _endDate?.toIso8601String(),
        'options': options,
      };

      final success = await voteProvider.createVote(voteData);
      
      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vote créé avec succès !'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Créer un vote'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Vote Title
              CustomTextField(
                controller: _titleController,
                label: 'Titre du vote',
                hint: 'Entrez le titre du vote',
                prefixIcon: Icons.poll,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir un titre';
                  }
                  if (value.length < 5) {
                    return 'Le titre doit contenir au moins 5 caractères';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Description
              CustomTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Décrivez le vote',
                prefixIcon: Icons.description,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir une description';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Vote Type
              const Text(
                'Type de vote',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Choix unique'),
                      subtitle: const Text('Une seule option peut être sélectionnée'),
                      value: 'SINGLE_CHOICE',
                      groupValue: _voteType,
                      onChanged: (value) {
                        setState(() {
                          _voteType = value!;
                        });
                      },
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      title: const Text('Choix multiple'),
                      subtitle: const Text('Plusieurs options peuvent être sélectionnées'),
                      value: 'MULTIPLE_CHOICE',
                      groupValue: _voteType,
                      onChanged: (value) {
                        setState(() {
                          _voteType = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Options
              const Text(
                'Options de vote',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              
              ..._buildOptionFields(),
              
              const SizedBox(height: 12),
              
              TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une option'),
              ),
              
              const SizedBox(height: 24),
              
              // End Date
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.schedule, color: AppTheme.primaryColor),
                  title: const Text('Date de fin (optionnel)'),
                  subtitle: Text(
                    _endDate != null
                        ? 'Se termine le ${_formatDate(_endDate!)}'
                        : 'Fermeture manuelle',
                  ),
                  trailing: _endDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _endDate = null;
                            });
                          },
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _selectEndDate,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Anonymous Setting
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: const Text('Vote anonyme'),
                  subtitle: const Text('Les votes ne seront pas associés aux utilisateurs'),
                  value: _isAnonymous,
                  onChanged: (value) {
                    setState(() {
                      _isAnonymous = value;
                    });
                  },
                  activeColor: AppTheme.primaryColor,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Create Button
              Consumer<VoteProvider>(
                builder: (context, voteProvider, child) {
                  return CustomButton(
                    text: 'Créer le vote',
                    onPressed: voteProvider.isLoading ? null : _createVote,
                    isLoading: voteProvider.isLoading,
                    icon: Icons.poll,
                  );
                },
              ),
              
              // Error Message
              Consumer<VoteProvider>(
                builder: (context, voteProvider, child) {
                  if (voteProvider.error != null) {
                    return Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        voteProvider.error!,
                        style: const TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOptionFields() {
    return _optionControllers.asMap().entries.map((entry) {
      final index = entry.key;
      final controller = entry.value;
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Option ${index + 1}',
                  hintText: 'Entrez une option',
                  prefixIcon: Icon(
                    _voteType == 'SINGLE_CHOICE' 
                        ? Icons.radio_button_unchecked 
                        : Icons.check_box_outline_blank,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                ),
                validator: index < 2 ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Cette option est requise';
                  }
                  return null;
                } : null,
              ),
            ),
            if (_optionControllers.length > 2)
              IconButton(
                onPressed: () => _removeOption(index),
                icon: const Icon(Icons.remove_circle, color: AppTheme.errorColor),
              ),
          ],
        ),
      );
    }).toList();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}