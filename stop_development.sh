#!/bin/bash

# Script para detener el entorno completo de desarrollo ZONIX-EATS
# Autor: ZONIX-EATS Team

echo "🛑 Deteniendo entorno de desarrollo ZONIX-EATS..."

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes con colores
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detener Laravel Echo Server
print_status "Deteniendo Laravel Echo Server..."
if [ -f "../zonix-eats-back/echo-server.pid" ]; then
    ECHO_PID=$(cat ../zonix-eats-back/echo-server.pid)
    if kill -0 $ECHO_PID 2>/dev/null; then
        kill $ECHO_PID
        print_success "Laravel Echo Server detenido (PID: $ECHO_PID)"
    else
        print_warning "Laravel Echo Server ya no está ejecutándose"
    fi
    rm -f ../zonix-eats-back/echo-server.pid
else
    print_warning "No se encontró PID de Laravel Echo Server"
fi

# Detener servidor Laravel
print_status "Deteniendo servidor Laravel..."
if [ -f "../zonix-eats-back/laravel-server.pid" ]; then
    LARAVEL_PID=$(cat ../zonix-eats-back/laravel-server.pid)
    if kill -0 $LARAVEL_PID 2>/dev/null; then
        kill $LARAVEL_PID
        print_success "Servidor Laravel detenido (PID: $LARAVEL_PID)"
    else
        print_warning "Servidor Laravel ya no está ejecutándose"
    fi
    rm -f ../zonix-eats-back/laravel-server.pid
else
    print_warning "No se encontró PID de servidor Laravel"
fi

# Detener procesos de Flutter
print_status "Deteniendo procesos de Flutter..."
pkill -f "flutter run" 2>/dev/null || true
pkill -f "dart" 2>/dev/null || true
print_success "Procesos de Flutter detenidos"

# Detener Redis (opcional)
read -p "¿Deseas detener Redis también? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Deteniendo Redis..."
    sudo systemctl stop redis-server
    print_success "Redis detenido"
else
    print_status "Redis seguirá ejecutándose"
fi

# Limpiar archivos temporales
print_status "Limpiando archivos temporales..."
rm -f ../zonix-eats-back/echo-server.pid
rm -f ../zonix-eats-back/laravel-server.pid
rm -f ../zonix-eats-back/echo-server.log

print_success "🎉 Todos los servicios han sido detenidos correctamente"
echo ""
echo "📋 Servicios detenidos:"
echo "  • Laravel Echo Server"
echo "  • Servidor Laravel"
echo "  • Procesos de Flutter"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "  • Redis Server"
fi
echo ""
print_warning "Para reiniciar todos los servicios, ejecuta: ./start_development.sh" 