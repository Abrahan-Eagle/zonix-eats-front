import 'package:flutter/material.dart';

class OnboardingPage2 extends StatefulWidget {
  const OnboardingPage2({super.key});

  @override
  State<OnboardingPage2> createState() => _OnboardingPage2State();
}

class _OnboardingPage2State extends State<OnboardingPage2>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutCubic),
    );
    
    _floatingAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );
    
    _mainController.forward();
    _floatingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _mainController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isSmallPhone = size.width < 360;
    
    return Scaffold(
      backgroundColor: const Color(0xFF27AE60),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 64.0 : (isSmallPhone ? 16.0 : 20.0),
                    vertical: isTablet ? 32.0 : 16.0,
                  ),
                  child: AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: IntrinsicHeight(
                            child: Column(
                              children: [
                                // Espaciador flexible inicial
                                const Flexible(flex: 1, child: SizedBox()),
                                
                                // Ilustración principal con elementos flotantes
                                Container(
                                  height: constraints.maxHeight * (isTablet ? 0.32 : 0.28),
                                  child: _buildMainIllustration(size, isTablet, isSmallPhone),
                                ),
                                
                                // Espaciador
                                SizedBox(height: isTablet ? 32 : (isSmallPhone ? 16 : 24)),
                                
                                // Contenido principal
                                _buildMainContent(isTablet, isSmallPhone),
                                
                                // Espaciador
                                SizedBox(height: isTablet ? 24 : (isSmallPhone ? 16 : 20)),
                                
                                // Estadísticas o beneficios
                                _buildStatsSection(isTablet, isSmallPhone),
                                
                                // Espaciador flexible final
                                const Flexible(flex: 1, child: SizedBox()),
                                
                                // Espacio para la navegación flotante
                                const SizedBox(height: 80),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainIllustration(Size size, bool isTablet, bool isSmallPhone) {
    final illustrationSize = isTablet 
        ? size.width * 0.45 
        : isSmallPhone 
            ? size.width * 0.65 
            : size.width * 0.7;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // Fondo circular
        Container(
          width: illustrationSize,
          height: illustrationSize,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(illustrationSize / 2),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
        ),
        
        // Elementos flotantes animados
        AnimatedBuilder(
          animation: _floatingAnimation,
          builder: (context, child) {
            return Stack(
              children: [
                // Carrito de compras
                Positioned(
                  top: 20 + _floatingAnimation.value,
                  left: isSmallPhone ? 15 : 25,
                  child: _buildFloatingIcon(
                    Icons.shopping_cart,
                    const Color(0xFFF39C12),
                    isTablet,
                    isSmallPhone,
                  ),
                ),
                
                // Pizza
                Positioned(
                  top: 30 - _floatingAnimation.value,
                  right: isSmallPhone ? 20 : 35,
                  child: _buildFloatingIcon(
                    Icons.local_pizza,
                    const Color(0xFFE74C3C),
                    isTablet,
                    isSmallPhone,
                  ),
                ),
                
                // Hamburguesa
                Positioned(
                  bottom: 30 + _floatingAnimation.value * 0.5,
                  left: isSmallPhone ? 35 : 50,
                  child: _buildFloatingIcon(
                    Icons.lunch_dining,
                    const Color(0xFF8E44AD),
                    isTablet,
                    isSmallPhone,
                  ),
                ),
                
                // Bebida
                Positioned(
                  bottom: 20 - _floatingAnimation.value,
                  right: isSmallPhone ? 30 : 40,
                  child: _buildFloatingIcon(
                    Icons.local_drink,
                    const Color(0xFF3498DB),
                    isTablet,
                    isSmallPhone,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMainContent(bool isTablet, bool isSmallPhone) {
    return Column(
      children: [
        Text(
          'Pedidos Fáciles',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isTablet ? 36 : (isSmallPhone ? 24 : 28),
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        
        SizedBox(height: isTablet ? 20 : (isSmallPhone ? 12 : 16)),
        
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isTablet ? 24 : (isSmallPhone ? 16 : 20)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Explora miles de restaurantes y platos. Ordena con unos pocos toques y disfruta de la mejor comida en tu puerta.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF2C3E50),
                  fontSize: isTablet ? 18 : (isSmallPhone ? 13 : 15),
                  height: 1.5,
                ),
              ),
              
              SizedBox(height: isTablet ? 28 : (isSmallPhone ? 16 : 20)),
              
              // Proceso de pedido - Responsive
              _buildProcessSteps(isTablet, isSmallPhone),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessSteps(bool isTablet, bool isSmallPhone) {
    if (isSmallPhone) {
      // Para pantallas muy pequeñas, layout vertical
      return Column(
        children: [
          _buildStep('1', 'Explora', const Color(0xFFE74C3C), isTablet, isSmallPhone),
          SizedBox(height: 12),
          Icon(Icons.keyboard_arrow_down, color: const Color(0xFF95A5A6), size: 20),
          SizedBox(height: 12),
          _buildStep('2', 'Ordena', const Color(0xFFF39C12), isTablet, isSmallPhone),
          SizedBox(height: 12),
          Icon(Icons.keyboard_arrow_down, color: const Color(0xFF95A5A6), size: 20),
          SizedBox(height: 12),
          _buildStep('3', 'Disfruta', const Color(0xFF27AE60), isTablet, isSmallPhone),
        ],
      );
    } else {
      // Layout horizontal para pantallas normales
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Flexible(
            child: _buildStep('1', 'Explora', const Color(0xFFE74C3C), isTablet, isSmallPhone),
          ),
          _buildArrow(isTablet, isSmallPhone),
          Flexible(
            child: _buildStep('2', 'Ordena', const Color(0xFFF39C12), isTablet, isSmallPhone),
          ),
          _buildArrow(isTablet, isSmallPhone),
          Flexible(
            child: _buildStep('3', 'Disfruta', const Color(0xFF27AE60), isTablet, isSmallPhone),
          ),
        ],
      );
    }
  }

  Widget _buildStatsSection(bool isTablet, bool isSmallPhone) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isTablet ? 16 : (isSmallPhone ? 12 : 14),
        horizontal: isTablet ? 24 : (isSmallPhone ? 16 : 20),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Flexible(child: _buildStat('1000+', 'Restaurantes', isTablet, isSmallPhone)),
          Container(
            width: 1, 
            height: isSmallPhone ? 30 : 35, 
            color: Colors.white.withOpacity(0.3)
          ),
          Flexible(child: _buildStat('50k+', 'Pedidos', isTablet, isSmallPhone)),
          Container(
            width: 1, 
            height: isSmallPhone ? 30 : 35, 
            color: Colors.white.withOpacity(0.3)
          ),
          Flexible(child: _buildStat('4.8★', 'Rating', isTablet, isSmallPhone)),
        ],
      ),
    );
  }

  Widget _buildFloatingIcon(IconData icon, Color color, bool isTablet, bool isSmallPhone) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : (isSmallPhone ? 8 : 10)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: color,
        size: isTablet ? 32 : (isSmallPhone ? 20 : 24),
      ),
    );
  }

  Widget _buildStep(String number, String label, Color color, bool isTablet, bool isSmallPhone) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isTablet ? 50 : (isSmallPhone ? 35 : 40),
          height: isTablet ? 50 : (isSmallPhone ? 35 : 40),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 20 : (isSmallPhone ? 14 : 16),
              ),
            ),
          ),
        ),
        SizedBox(height: isTablet ? 12 : (isSmallPhone ? 6 : 8)),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF2C3E50),
            fontSize: isTablet ? 14 : (isSmallPhone ? 10 : 12),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildArrow(bool isTablet, bool isSmallPhone) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmallPhone ? 4 : 8),
      child: Icon(
        Icons.arrow_forward,
        color: const Color(0xFF95A5A6),
        size: isTablet ? 24 : (isSmallPhone ? 16 : 18),
      ),
    );
  }

  Widget _buildStat(String value, String label, bool isTablet, bool isSmallPhone) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 24 : (isSmallPhone ? 16 : 18),
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: isTablet ? 14 : (isSmallPhone ? 9 : 11),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}