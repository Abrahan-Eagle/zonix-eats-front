import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DeliveryCompanyRegistrationPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final bool isEditing;
  
  const DeliveryCompanyRegistrationPage({
    super.key, 
    this.initialData, 
    this.isEditing = false
  });

  @override
  State<DeliveryCompanyRegistrationPage> createState() => _DeliveryCompanyRegistrationPageState();
}

class _DeliveryCompanyRegistrationPageState extends State<DeliveryCompanyRegistrationPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Form controllers
  final _nombreController = TextEditingController();
  final _rucController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  
  // Profile controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isLoading = false;
  bool _activo = true;
  String _selectedSex = 'M';
  String _selectedMaritalStatus = 'single';
  
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
    _nombreController.text = data['nombre'] ?? '';
    _rucController.text = data['ruc'] ?? '';
    _telefonoController.text = data['telefono'] ?? '';
    _direccionController.text = data['direccion'] ?? '';
    _activo = data['activo'] ?? true;
    
    // Datos del perfil
    _firstNameController.text = data['firstName'] ?? '';
    _lastNameController.text = data['lastName'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _addressController.text = data['address'] ?? '';
    _selectedSex = data['sex'] ?? 'M';
    _selectedMaritalStatus = data['maritalStatus'] ?? 'single';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _nombreController.dispose();
    _rucController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isSmallPhone = size.width < 360;
    
    return Scaffold(
      backgroundColor: const Color(0xFF2E86C1),
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
                  backgroundColor: Colors.white.withOpacity(0.2),
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
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.local_shipping,
              size: isTablet ? 40 : (isSmallPhone ? 30 : 35),
              color: const Color(0xFF2E86C1),
            ),
          ),
          
          SizedBox(height: isTablet ? 24 : 16),
          
          Text(
            widget.isEditing ? 'Editar Empresa de Delivery' : 'Registra tu Empresa de Delivery',
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
              ? 'Actualiza la información de tu empresa'
              : 'Completa la información de tu empresa para comenzar a operar',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 16 : (isSmallPhone ? 12 : 14),
              color: Colors.white.withOpacity(0.9),
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
            color: Colors.black.withOpacity(0.1),
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
                    validator: (value) => value?.isEmpty == true ? 'Este campo es obligatorio' : null,
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
                    validator: (value) => value?.isEmpty == true ? 'Este campo es obligatorio' : null,
                    isTablet: isTablet,
                    isSmallPhone: isSmallPhone,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: isTablet ? 20 : 16),
            
            _buildTextField(
              controller: _phoneController,
              label: 'Teléfono Personal',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) => value?.isEmpty == true ? 'Este campo es obligatorio' : null,
              isTablet: isTablet,
              isSmallPhone: isSmallPhone,
            ),
            
            SizedBox(height: isTablet ? 20 : 16),
            
            _buildTextField(
              controller: _addressController,
              label: 'Dirección Personal',
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
            
            // Información de la empresa
            _buildSectionTitle('Información de la Empresa', isTablet, isSmallPhone),
            SizedBox(height: isTablet ? 20 : 16),
            
            _buildTextField(
              controller: _nombreController,
              label: 'Nombre de la Empresa',
              icon: Icons.business_outlined,
              validator: (value) => value?.isEmpty == true ? 'Este campo es obligatorio' : null,
              isTablet: isTablet,
              isSmallPhone: isSmallPhone,
            ),
            
            SizedBox(height: isTablet ? 20 : 16),
            
            _buildTextField(
              controller: _rucController,
              label: 'RUC',
              icon: Icons.numbers_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) => value?.isEmpty == true ? 'Este campo es obligatorio' : null,
              isTablet: isTablet,
              isSmallPhone: isSmallPhone,
            ),
            
            SizedBox(height: isTablet ? 20 : 16),
            
            _buildTextField(
              controller: _telefonoController,
              label: 'Teléfono de la Empresa',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) => value?.isEmpty == true ? 'Este campo es obligatorio' : null,
              isTablet: isTablet,
              isSmallPhone: isSmallPhone,
            ),
            
            SizedBox(height: isTablet ? 20 : 16),
            
            _buildTextField(
              controller: _direccionController,
              label: 'Dirección de la Empresa',
              icon: Icons.location_on_outlined,
              maxLines: 3,
              validator: (value) => value?.isEmpty == true ? 'Este campo es obligatorio' : null,
              isTablet: isTablet,
              isSmallPhone: isSmallPhone,
            ),
            
            SizedBox(height: isTablet ? 32 : 24),
            
            // Estado de la empresa
            _buildSectionTitle('Estado de la Empresa', isTablet, isSmallPhone),
            SizedBox(height: isTablet ? 16 : 12),
            
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
                    _activo ? Icons.check_circle : Icons.cancel,
                    color: _activo ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
                    size: isTablet ? 24 : 20,
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Expanded(
                    child: Text(
                      'Empresa ${_activo ? 'activa' : 'inactiva'}',
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Switch(
                    value: _activo,
                    onChanged: (value) => setState(() => _activo = value),
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
        prefixIcon: Icon(icon, color: const Color(0xFF2E86C1)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E86C1), width: 2),
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
      value: value,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: isTablet ? 16 : (isSmallPhone ? 13 : 14),
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2E86C1)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E86C1), width: 2),
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
          foregroundColor: const Color(0xFF2E86C1),
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
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E86C1)),
                ),
              )
            : Text(
                widget.isEditing ? 'Actualizar Empresa' : 'Registrar Empresa',
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
      setState(() => _isLoading = true);
      
      try {
        // Aquí implementarías la lógica para enviar los datos al backend
        await Future.delayed(const Duration(seconds: 2)); // Simulación
        
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing 
              ? 'Empresa actualizada exitosamente' 
              : 'Empresa registrada exitosamente'),
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