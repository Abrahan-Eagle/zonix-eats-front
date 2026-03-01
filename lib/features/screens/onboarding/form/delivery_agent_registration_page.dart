import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DeliveryAgentRegistrationPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final bool isEditing;
  
  const DeliveryAgentRegistrationPage({
    super.key, 
    this.initialData, 
    this.isEditing = false
  });

  @override
  State<DeliveryAgentRegistrationPage> createState() => _DeliveryAgentRegistrationPageState();
}

class _DeliveryAgentRegistrationPageState extends State<DeliveryAgentRegistrationPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Profile controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  // Delivery agent specific controllers
  final _vehicleTypeController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  
  bool _isLoading = false;
  String _selectedSex = 'M';
  String _selectedMaritalStatus = 'single';
  String _selectedEstado = 'activo';
  bool _trabajando = false;
  String _selectedCompany = '';
  
  // Lista simulada de empresas de delivery
  final List<Map<String, String>> _companies = [
    {'id': '1', 'name': 'Express Delivery S.A.'},
    {'id': '2', 'name': 'Rapid Transport'},
    {'id': '3', 'name': 'Fast Courier'},
  ];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _animationController.forward();
    
    // Cargar datos iniciales si es edición
    if (widget.isEditing && widget.initialData != null) {
      _loadInitialData();
    }
  }

  void _loadInitialData() {
    final data = widget.initialData!;
    _firstNameController.text = data['firstName'] ?? '';
    _lastNameController.text = data['lastName'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _addressController.text = data['address'] ?? '';
    _selectedSex = data['sex'] ?? 'M';
    _selectedMaritalStatus = data['maritalStatus'] ?? 'single';
    
    // Datos específicos del repartidor
    _vehicleTypeController.text = data['vehicle_type'] ?? '';
    _licenseNumberController.text = data['license_number'] ?? '';
    _selectedEstado = data['estado'] ?? 'activo';
    _trabajando = data['trabajando'] ?? false;
    _selectedCompany = data['company_id'] ?? '';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _vehicleTypeController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isSmallPhone = size.width < 360;
    
    return Scaffold(
      backgroundColor: const Color(0xFF8E44AD),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: _buildHeader(isTablet, isSmallPhone),
                    ),
                    
                    // Form Content
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 64.0 : (isSmallPhone ? 16.0 : 20.0),
                        ),
                        child: _buildFormContent(isTablet, isSmallPhone),
                      ),
                    ),
                    
                    // Bottom spacing
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: _buildSubmitButton(isTablet, isSmallPhone),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader(bool isTablet, bool isSmallPhone) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 32 : (isSmallPhone ? 16 : 24)),
      child: Column(
        children: [
          // Back button
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
          
          SizedBox(height: isTablet ? 20 : 12),
          
          // Icon
          Container(
            width: isTablet ? 80 : (isSmallPhone ? 60 : 70),
            height: isTablet ? 80 : (isSmallPhone ? 60 : 70),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.delivery_dining,
              size: isTablet ? 40 : (isSmallPhone ? 30 : 35),
              color: const Color(0xFF8E44AD),
            ),
          ),
          
          SizedBox(height: isTablet ? 24 : 16),
          
          Text(
            widget.isEditing ? 'Editar Perfil de Repartidor' : 'Registra tu Perfil de Repartidor',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 32 : (isSmallPhone ? 24 : 28),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          SizedBox(height: isTablet ? 12 : 8),
          
          Text(
            widget.isEditing 
              ? 'Actualiza tu información de repartidor'
              : 'Completa tu información para comenzar a trabajar como repartidor',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 16 : (isSmallPhone ? 12 : 14),
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent(bool isTablet, bool isSmallPhone) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 32 : (isSmallPhone ? 20 : 24)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información personal
            _buildSectionTitle('Información Personal', isTablet, isSmallPhone),
            SizedBox(height: isTablet ? 20 : 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _firstNameController,
                    label: 'Nombre',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Este campo es obligatorio';
                      if (value.trim().length < 3) return 'Mínimo 3 caracteres';
                      if (value.trim().length > 100) return 'Máximo 100 caracteres';
                      if (!RegExp(r'^[a-zA-Z áéíóúÁÉÍÓÚüÜñÑ]+$').hasMatch(value)) return 'Solo letras y espacios';
                      return null;
                    },
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z áéíóúÁÉÍÓÚüÜñÑ]'))],
                    isTablet: isTablet,
                    isSmallPhone: isSmallPhone,
                  ),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Expanded(
                  child: _buildTextField(
                    controller: _lastNameController,
                    label: 'Apellido',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Este campo es obligatorio';
                      if (value.trim().length < 3) return 'Mínimo 3 caracteres';
                      if (value.trim().length > 100) return 'Máximo 100 caracteres';
                      if (!RegExp(r'^[a-zA-Z áéíóúÁÉÍÓÚüÜñÑ]+$').hasMatch(value)) return 'Solo letras y espacios';
                      return null;
                    },
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z áéíóúÁÉÍÓÚüÜñÑ]'))],
                    isTablet: isTablet,
                    isSmallPhone: isSmallPhone,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: isTablet ? 20 : 16),
            
            _buildTextField(
              controller: _phoneController,
              label: 'Teléfono',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Este campo es obligatorio';
                if (value.trim().length < 10) return 'Mínimo 10 dígitos';
                if (value.trim().length > 15) return 'Máximo 15 dígitos';
                if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Solo números';
                return null;
              },
              isTablet: isTablet,
              isSmallPhone: isSmallPhone,
            ),
            
            SizedBox(height: isTablet ? 20 : 16),
            
            _buildTextField(
              controller: _addressController,
              label: 'Dirección',
              icon: Icons.location_on_outlined,
              maxLines: 3,
              validator: (value) => value?.isEmpty == true ? 'Este campo es obligatorio' : null,
              isTablet: isTablet,
              isSmallPhone: isSmallPhone,
            ),
            
            SizedBox(height: isTablet ? 20 : 16),
            
            // Sexo y Estado Civil
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField(
                    label: 'Sexo',
                    value: _selectedSex,
                    items: const [
                      {'value': 'M', 'label': 'Masculino'},
                      {'value': 'F', 'label': 'Femenino'},
                      {'value': 'O', 'label': 'Otro'},
                    ],
                    onChanged: (value) => setState(() => _selectedSex = value!),
                    isTablet: isTablet,
                    isSmallPhone: isSmallPhone,
                  ),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Expanded(
                  child: _buildDropdownField(
                    label: 'Estado Civil',
                    value: _selectedMaritalStatus,
                    items: const [
                      {'value': 'single', 'label': 'Soltero'},
                      {'value': 'married', 'label': 'Casado'},
                      {'value': 'divorced', 'label': 'Divorciado'},
                      {'value': 'widowed', 'label': 'Viudo'},
                    ],
                    onChanged: (value) => setState(() => _selectedMaritalStatus = value!),
                    isTablet: isTablet,
                    isSmallPhone: isSmallPhone,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: isTablet ? 32 : 24),
            
            // Información de repartidor
            _buildSectionTitle('Información de Repartidor', isTablet, isSmallPhone),
            SizedBox(height: isTablet ? 20 : 16),
            
            _buildDropdownField(
              label: 'Empresa de Delivery',
              value: _selectedCompany,
              items: _companies.map((company) => {
                'value': company['id']!,
                'label': company['name']!,
              }).toList(),
              onChanged: (value) => setState(() => _selectedCompany = value!),
              isTablet: isTablet,
              isSmallPhone: isSmallPhone,
            ),
            
            SizedBox(height: isTablet ? 20 : 16),
            
            _buildTextField(
              controller: _vehicleTypeController,
              label: 'Tipo de Vehículo',
              icon: Icons.two_wheeler,
              validator: (value) => value?.isEmpty == true ? 'Este campo es obligatorio' : null,
              isTablet: isTablet,
              isSmallPhone: isSmallPhone,
            ),
            
            SizedBox(height: isTablet ? 20 : 16),
            
            _buildTextField(
              controller: _licenseNumberController,
              label: 'Número de Licencia',
              icon: Icons.card_membership,
              validator: (value) => value?.isEmpty == true ? 'Este campo es obligatorio' : null,
              isTablet: isTablet,
              isSmallPhone: isSmallPhone,
            ),
            
            SizedBox(height: isTablet ? 32 : 24),
            
            // Estado del repartidor
            _buildSectionTitle('Estado del Repartidor', isTablet, isSmallPhone),
            SizedBox(height: isTablet ? 16 : 12),
            
            _buildDropdownField(
              label: 'Estado',
              value: _selectedEstado,
              items: const [
                {'value': 'activo', 'label': 'Activo'},
                {'value': 'inactivo', 'label': 'Inactivo'},
                {'value': 'suspendido', 'label': 'Suspendido'},
              ],
              onChanged: (value) => setState(() => _selectedEstado = value!),
              isTablet: isTablet,
              isSmallPhone: isSmallPhone,
            ),
            
            SizedBox(height: isTablet ? 20 : 16),
            
            Container(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E8E8)),
              ),
              child: Row(
                children: [
                  Icon(
                    _trabajando ? Icons.check_circle : Icons.cancel,
                    color: _trabajando ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
                    size: isTablet ? 24 : 20,
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Expanded(
                    child: Text(
                      'Repartidor ${_trabajando ? 'trabajando' : 'disponible'}',
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Switch(
                    value: _trabajando,
                    onChanged: (value) => setState(() => _trabajando = value),
                    activeColor: const Color(0xFF27AE60),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isTablet, bool isSmallPhone) {
    return Text(
      title,
      style: TextStyle(
        fontSize: isTablet ? 20 : (isSmallPhone ? 16 : 18),
        fontWeight: FontWeight.bold,
        color: const Color(0xFF2C3E50),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isTablet,
    required bool isSmallPhone,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: isTablet ? 16 : (isSmallPhone ? 13 : 14),
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF8E44AD)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8E44AD), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        labelStyle: TextStyle(
          fontSize: isTablet ? 14 : (isSmallPhone ? 12 : 13),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<Map<String, String>> items,
    required Function(String?) onChanged,
    required bool isTablet,
    required bool isSmallPhone,
  }) {
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: isTablet ? 16 : (isSmallPhone ? 13 : 14),
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF8E44AD)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8E44AD), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        labelStyle: TextStyle(
          fontSize: isTablet ? 14 : (isSmallPhone ? 12 : 13),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item['value'],
          child: Text(
            item['label']!,
            style: TextStyle(
              fontSize: isTablet ? 14 : (isSmallPhone ? 12 : 13),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubmitButton(bool isTablet, bool isSmallPhone) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 64 : 20),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF8E44AD),
          padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 8,
        ),
        child: _isLoading
            ? SizedBox(
                height: isTablet ? 24 : 20,
                width: isTablet ? 24 : 20,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E44AD)),
                ),
              )
            : Text(
                widget.isEditing ? 'Actualizar Repartidor' : 'Registrar Repartidor',
                style: TextStyle(
                  fontSize: isTablet ? 18 : (isSmallPhone ? 14 : 16),
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCompany.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes seleccionar una empresa de delivery'),
            backgroundColor: Color(0xFFE74C3C),
          ),
        );
        return;
      }
      
      setState(() => _isLoading = true);
      
      try {
        // Aquí implementarías la lógica para enviar los datos al backend
        await Future.delayed(const Duration(seconds: 2)); // Simulación
        
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing 
              ? 'Repartidor actualizado exitosamente' 
              : 'Repartidor registrado exitosamente'),
            backgroundColor: const Color(0xFF27AE60),
          ),
        );
        
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al ${widget.isEditing ? 'actualizar' : 'registrar'}: $e'),
            backgroundColor: const Color(0xFFE74C3C),
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
} 