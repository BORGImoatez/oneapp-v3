import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class Building3DViewScreen extends StatefulWidget {
  final String buildingId;
  final String buildingName;
  final List<Map<String, dynamic>> apartments;

  const Building3DViewScreen({
    super.key,
    required this.buildingId,
    required this.buildingName,
    required this.apartments,
  });

  @override
  State<Building3DViewScreen> createState() => _Building3DViewScreenState();
}

class _Building3DViewScreenState extends State<Building3DViewScreen> {
  Map<int, List<Map<String, dynamic>>> _apartmentsByFloor = {};
  int _maxFloor = 0;
  Map<String, dynamic>? _selectedApartment;

  @override
  void initState() {
    super.initState();
    _organizeApartmentsByFloor();
  }

  void _organizeApartmentsByFloor() {
    _apartmentsByFloor.clear();
    _maxFloor = 0;

    for (var apartment in widget.apartments) {
      final floor = apartment['apartmentFloor'] as int? ?? 0;
      if (floor > _maxFloor) _maxFloor = floor;

      if (!_apartmentsByFloor.containsKey(floor)) {
        _apartmentsByFloor[floor] = [];
      }
      _apartmentsByFloor[floor]!.add(apartment);
    }
  }

  Color _getApartmentColor(Map<String, dynamic> apartment) {
    return apartment['resident'] != null ? Colors.green : Colors.red;
  }

  String _getApartmentStatus(Map<String, dynamic> apartment) {
    return apartment['resident'] != null ? 'Occupé' : 'Vide';
  }

  void _showApartmentDetails(Map<String, dynamic> apartment) {
    setState(() {
      _selectedApartment = apartment;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _getApartmentColor(apartment).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.apartment,
                        color: _getApartmentColor(apartment),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            apartment['apartmentLabel'] ?? 'N/A',
                            style: AppTheme.titleStyle.copyWith(fontSize: 20),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getApartmentStatus(apartment),
                            style: TextStyle(
                              color: _getApartmentColor(apartment),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailRow('Numéro', apartment['apartmentNumber'] ?? 'N/A'),
                _buildDetailRow('Étage', '${apartment['apartmentFloor'] ?? 0}'),
                if (apartment['livingAreaSurface'] != null)
                  _buildDetailRow(
                    'Surface',
                    '${apartment['livingAreaSurface']} m²',
                  ),
                if (apartment['numberOfRooms'] != null)
                  _buildDetailRow(
                    'Pièces',
                    '${apartment['numberOfRooms']}',
                  ),
                if (apartment['numberOfBedrooms'] != null)
                  _buildDetailRow(
                    'Chambres',
                    '${apartment['numberOfBedrooms']}',
                  ),
                _buildDetailRow(
                  'Balcon/Terrasse',
                  apartment['haveBalconyOrTerrace'] == true ? 'Oui' : 'Non',
                ),
                _buildDetailRow(
                  'Meublé',
                  apartment['isFurnished'] == true ? 'Oui' : 'Non',
                ),
                if (apartment['resident'] != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Résident',
                    style: AppTheme.titleStyle.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Nom',
                    '${apartment['resident']['firstName'] ?? ''} ${apartment['resident']['lastName'] ?? ''}'
                        .trim(),
                  ),
                  if (apartment['resident']['email'] != null)
                    _buildDetailRow('Email', apartment['resident']['email']),
                  if (apartment['resident']['phoneNumber'] != null)
                    _buildDetailRow('Téléphone', apartment['resident']['phoneNumber']),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTheme.bodyStyle.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyStyle.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final floors = _apartmentsByFloor.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: Text('Vue 3D - ${widget.buildingName}'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem(Colors.green, 'Occupé'),
                _buildLegendItem(Colors.red, 'Vide'),
              ],
            ),
          ),
          Expanded(
            child: widget.apartments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.apartment_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun appartement',
                          style: AppTheme.titleStyle.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: floors.length,
                    itemBuilder: (context, index) {
                      final floor = floors[index];
                      final apartments = _apartmentsByFloor[floor]!;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _buildFloorSection(floor, apartments),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTheme.bodyStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFloorSection(int floor, List<Map<String, dynamic>> apartments) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Étage $floor',
                    style: AppTheme.titleStyle.copyWith(
                      color: AppTheme.primaryColor,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${apartments.length} app.',
                  style: AppTheme.bodyStyle.copyWith(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: apartments.map((apartment) {
                return _buildApartmentCard(apartment);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApartmentCard(Map<String, dynamic> apartment) {
    final color = _getApartmentColor(apartment);
    final isSelected = _selectedApartment?['idApartment'] == apartment['idApartment'];

    return InkWell(
      onTap: () => _showApartmentDetails(apartment),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              apartment['resident'] != null ? Icons.home : Icons.home_outlined,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              apartment['apartmentNumber']?.toString() ?? 'N/A',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              _getApartmentStatus(apartment),
              style: TextStyle(
                color: color,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
