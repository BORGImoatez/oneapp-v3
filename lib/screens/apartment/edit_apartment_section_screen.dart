import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/apartment_details_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/apartment_details_service.dart';

class EditApartmentSectionScreen extends StatefulWidget {
  final String apartmentId;
  final String section;
  final ApartmentDetailsModel? currentData;

  const EditApartmentSectionScreen({
    Key? key,
    required this.apartmentId,
    required this.section,
    this.currentData,
  }) : super(key: key);

  @override
  State<EditApartmentSectionScreen> createState() =>
      _EditApartmentSectionScreenState();
}

class _EditApartmentSectionScreenState
    extends State<EditApartmentSectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApartmentDetailsService _service = ApartmentDetailsService();
  bool _isLoading = false;

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _boolValues = {};
  String? _orientationTerrasse;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    switch (widget.section) {
      case 'general':
        _initController('nbChambres',
            widget.currentData?.generalInfo?.nbChambres?.toString());
        _initController('nbSalleBain',
            widget.currentData?.generalInfo?.nbSalleBain?.toString());
        _initController(
            'surface', widget.currentData?.generalInfo?.surface?.toString());
        _initController(
            'etage', widget.currentData?.generalInfo?.etage?.toString());
        break;

      case 'interior':
        _initController(
            'quartierLieu', widget.currentData?.interior?.quartierLieu);
        _initController('surfaceHabitable',
            widget.currentData?.interior?.surfaceHabitable?.toString());
        _initController('surfaceSalon',
            widget.currentData?.interior?.surfaceSalon?.toString());
        _initController('typeCuisine', widget.currentData?.interior?.typeCuisine);
        _initController('surfaceCuisine',
            widget.currentData?.interior?.surfaceCuisine?.toString());
        _initController('nbSalleDouche',
            widget.currentData?.interior?.nbSalleDouche?.toString());
        _initController('nbToilette',
            widget.currentData?.interior?.nbToilette?.toString());
        _boolValues['cave'] = widget.currentData?.interior?.cave ?? false;
        _boolValues['grenier'] = widget.currentData?.interior?.grenier ?? false;
        break;

      case 'exterior':
        _initController('surfaceTerrasse',
            widget.currentData?.exterior?.surfaceTerrasse?.toString());
        _orientationTerrasse =
            widget.currentData?.exterior?.orientationTerrasse;
        break;

      case 'installations':
        _boolValues['ascenseur'] =
            widget.currentData?.installations?.ascenseur ?? false;
        _boolValues['accesHandicap'] =
            widget.currentData?.installations?.accesHandicap ?? false;
        _boolValues['parlophone'] =
            widget.currentData?.installations?.parlophone ?? false;
        _boolValues['interphoneVideo'] =
            widget.currentData?.installations?.interphoneVideo ?? false;
        _boolValues['porteBlindee'] =
            widget.currentData?.installations?.porteBlindee ?? false;
        _boolValues['piscine'] =
            widget.currentData?.installations?.piscine ?? false;
        break;

      case 'energie':
        _initController('classeEnergetique',
            widget.currentData?.energie?.classeEnergetique);
        _initController('consommationEnergiePrimaire',
            widget.currentData?.energie?.consommationEnergiePrimaire?.toString());
        _initController('consommationTheoriqueTotale',
            widget.currentData?.energie?.consommationTheoriqueTotale?.toString());
        _initController('emissionCo2',
            widget.currentData?.energie?.emissionCo2?.toString());
        _initController(
            'numeroRapportPeb', widget.currentData?.energie?.numeroRapportPeb);
        _initController(
            'typeChauffage', widget.currentData?.energie?.typeChauffage);
        _boolValues['doubleVitrage'] =
            widget.currentData?.energie?.doubleVitrage ?? false;
        break;
    }
  }

  void _initController(String key, String? initialValue) {
    _controllers[key] = TextEditingController(text: initialValue ?? '');
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final updates = _buildUpdatePayload();

      await _service.updateApartmentDetails(
        widget.apartmentId,
        updates,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modifications enregistrées')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Map<String, dynamic> _buildUpdatePayload() {
    Map<String, dynamic> payload = {};

    switch (widget.section) {
      case 'general':
        payload['generalInfo'] = {
          'nbChambres': _parseIntOrNull(_controllers['nbChambres']?.text),
          'nbSalleBain': _parseIntOrNull(_controllers['nbSalleBain']?.text),
          'surface': _parseDoubleOrNull(_controllers['surface']?.text),
          'etage': _parseIntOrNull(_controllers['etage']?.text),
        };
        break;

      case 'interior':
        payload['interior'] = {
          'quartierLieu': _controllers['quartierLieu']?.text,
          'surfaceHabitable':
              _parseDoubleOrNull(_controllers['surfaceHabitable']?.text),
          'surfaceSalon':
              _parseDoubleOrNull(_controllers['surfaceSalon']?.text),
          'typeCuisine': _controllers['typeCuisine']?.text,
          'surfaceCuisine':
              _parseDoubleOrNull(_controllers['surfaceCuisine']?.text),
          'surfaceChambres': [],
          'nbSalleDouche':
              _parseIntOrNull(_controllers['nbSalleDouche']?.text),
          'nbToilette': _parseIntOrNull(_controllers['nbToilette']?.text),
          'cave': _boolValues['cave'],
          'grenier': _boolValues['grenier'],
        };
        break;

      case 'exterior':
        payload['exterior'] = {
          'surfaceTerrasse':
              _parseDoubleOrNull(_controllers['surfaceTerrasse']?.text),
          'orientationTerrasse': _orientationTerrasse,
        };
        break;

      case 'installations':
        payload['installations'] = {
          'ascenseur': _boolValues['ascenseur'],
          'accesHandicap': _boolValues['accesHandicap'],
          'parlophone': _boolValues['parlophone'],
          'interphoneVideo': _boolValues['interphoneVideo'],
          'porteBlindee': _boolValues['porteBlindee'],
          'piscine': _boolValues['piscine'],
        };
        break;

      case 'energie':
        payload['energie'] = {
          'classeEnergetique': _controllers['classeEnergetique']?.text,
          'consommationEnergiePrimaire': _parseDoubleOrNull(
              _controllers['consommationEnergiePrimaire']?.text),
          'consommationTheoriqueTotale': _parseDoubleOrNull(
              _controllers['consommationTheoriqueTotale']?.text),
          'emissionCo2': _parseDoubleOrNull(_controllers['emissionCo2']?.text),
          'numeroRapportPeb': _controllers['numeroRapportPeb']?.text,
          'typeChauffage': _controllers['typeChauffage']?.text,
          'doubleVitrage': _boolValues['doubleVitrage'],
        };
        break;
    }

    return payload;
  }

  int? _parseIntOrNull(String? value) {
    if (value == null || value.isEmpty) return null;
    return int.tryParse(value);
  }

  double? _parseDoubleOrNull(String? value) {
    if (value == null || value.isEmpty) return null;
    return double.tryParse(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getSectionTitle()),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveChanges,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: _buildFormFields(),
        ),
      ),
    );
  }

  String _getSectionTitle() {
    switch (widget.section) {
      case 'general':
        return 'Informations Générales';
      case 'interior':
        return 'Intérieur';
      case 'exterior':
        return 'Extérieur';
      case 'installations':
        return 'Installations';
      case 'energie':
        return 'Énergie';
      default:
        return 'Modifier';
    }
  }

  List<Widget> _buildFormFields() {
    switch (widget.section) {
      case 'general':
        return _buildGeneralFields();
      case 'interior':
        return _buildInteriorFields();
      case 'exterior':
        return _buildExteriorFields();
      case 'installations':
        return _buildInstallationsFields();
      case 'energie':
        return _buildEnergieFields();
      default:
        return [];
    }
  }

  List<Widget> _buildGeneralFields() {
    return [
      _buildNumberField('nbChambres', 'Nombre de chambres'),
      _buildNumberField('nbSalleBain', 'Nombre de salles de bain'),
      _buildDecimalField('surface', 'Surface (m²)'),
      _buildNumberField('etage', 'Étage'),
    ];
  }

  List<Widget> _buildInteriorFields() {
    return [
      _buildTextField('quartierLieu', 'Quartier/Lieu'),
      _buildDecimalField('surfaceHabitable', 'Surface habitable (m²)'),
      _buildDecimalField('surfaceSalon', 'Surface salon (m²)'),
      _buildTextField('typeCuisine', 'Type de cuisine'),
      _buildDecimalField('surfaceCuisine', 'Surface cuisine (m²)'),
      _buildNumberField('nbSalleDouche', 'Nombre de salles de douche'),
      _buildNumberField('nbToilette', 'Nombre de toilettes'),
      _buildSwitchField('cave', 'Cave'),
      _buildSwitchField('grenier', 'Grenier'),
    ];
  }

  List<Widget> _buildExteriorFields() {
    return [
      _buildDecimalField('surfaceTerrasse', 'Surface terrasse (m²)'),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: DropdownButtonFormField<String>(
          value: _orientationTerrasse,
          decoration: const InputDecoration(
            labelText: 'Orientation terrasse',
            border: OutlineInputBorder(),
          ),
          items: ['SUD', 'NORD', 'EST', 'OUEST']
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (value) => setState(() => _orientationTerrasse = value),
        ),
      ),
    ];
  }

  List<Widget> _buildInstallationsFields() {
    return [
      _buildSwitchField('ascenseur', 'Ascenseur'),
      _buildSwitchField('accesHandicap', 'Accès handicapé'),
      _buildSwitchField('parlophone', 'Parlophone'),
      _buildSwitchField('interphoneVideo', 'Interphone vidéo'),
      _buildSwitchField('porteBlindee', 'Porte blindée'),
      _buildSwitchField('piscine', 'Piscine'),
    ];
  }

  List<Widget> _buildEnergieFields() {
    return [
      _buildTextField('classeEnergetique', 'Classe énergétique'),
      _buildDecimalField('consommationEnergiePrimaire',
          'Consommation énergie primaire (kWh/m²/an)'),
      _buildDecimalField('consommationTheoriqueTotale',
          'Consommation théorique totale (kWh/an)'),
      _buildDecimalField('emissionCo2', 'Émission CO2 (kg/m²/an)'),
      _buildTextField('numeroRapportPeb', 'Numéro rapport PEB'),
      _buildTextField('typeChauffage', 'Type de chauffage'),
      _buildSwitchField('doubleVitrage', 'Double vitrage'),
    ];
  }

  Widget _buildTextField(String key, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: _controllers[key],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildNumberField(String key, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: _controllers[key],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }

  Widget _buildDecimalField(String key, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: _controllers[key],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }

  Widget _buildSwitchField(String key, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SwitchListTile(
        title: Text(label),
        value: _boolValues[key] ?? false,
        onChanged: (value) => setState(() => _boolValues[key] = value),
      ),
    );
  }
}
