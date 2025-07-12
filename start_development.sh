#!/bin/bash

# Script para iniciar el entorno completo de desarrollo ZONIX-EATS
# Autor: ZONIX-EATS Team
# Fecha: $(date)

echo "🚀 Iniciando entorno completo de desarrollo ZONIX-EATS..."

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

# Verificar dependencias
print_status "Verificando dependencias..."

# Verificar Node.js
if ! command -v node &> /dev/null; then
    print_error "Node.js no está instalado"
    echo "Por favor instala Node.js desde https://nodejs.org/"
    exit 1
fi

# Verificar PHP
if ! command -v php &> /dev/null; then
    print_error "PHP no está instalado"
    echo "Por favor instala PHP 8.1 o superior"
    exit 1
fi

# Verificar Composer
if ! command -v composer &> /dev/null; then
    print_error "Composer no está instalado"
    echo "Por favor instala Composer desde https://getcomposer.org/"
    exit 1
fi

# Verificar Flutter
if ! command -v flutter &> /dev/null; then
    print_error "Flutter no está instalado"
    echo "Por favor instala Flutter desde https://flutter.dev/"
    exit 1
fi

# Verificar Redis
if ! command -v redis-server &> /dev/null; then
    print_warning "Redis no está instalado"
    echo "Instalando Redis..."
    sudo apt-get update
    sudo apt-get install -y redis-server
fi

print_success "Todas las dependencias están instaladas"

# Iniciar Redis
print_status "Iniciando Redis..."
sudo systemctl start redis-server
sudo systemctl enable redis-server
print_success "Redis iniciado"

# Configurar backend Laravel
print_status "Configurando backend Laravel..."
cd ../zonix-eats-back

# Instalar dependencias de PHP
if [ ! -d "vendor" ]; then
    print_status "Instalando dependencias de PHP..."
    composer install
fi

# Copiar archivo de entorno si no existe
if [ ! -f ".env" ]; then
    print_status "Copiando archivo de entorno..."
    cp .env.example .env
    print_warning "Por favor edita el archivo .env con tus configuraciones"
fi

# Generar clave de aplicación
print_status "Generando clave de aplicación..."
php artisan key:generate

# Ejecutar migraciones
print_status "Ejecutando migraciones..."
php artisan migrate --force

# Ejecutar seeders
print_status "Ejecutando seeders..."
php artisan db:seed --force

# Limpiar caché
print_status "Limpiando caché..."
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

print_success "Backend Laravel configurado"

# Instalar laravel-echo-server globalmente
print_status "Instalando laravel-echo-server..."
npm install -g laravel-echo-server

# Iniciar Laravel Echo Server en background
print_status "Iniciando Laravel Echo Server..."
laravel-echo-server start --config=laravel-echo-server.json &
ECHO_PID=$!
echo $ECHO_PID > echo-server.pid
print_success "Laravel Echo Server iniciado (PID: $ECHO_PID)"

# Iniciar servidor Laravel en background
print_status "Iniciando servidor Laravel..."
php artisan serve --host=0.0.0.0 --port=8000 &
LARAVEL_PID=$!
echo $LARAVEL_PID > laravel-server.pid
print_success "Servidor Laravel iniciado (PID: $LARAVEL_PID)"

# Volver al directorio del frontend
cd ../zonix-eats-front

# Instalar dependencias de Flutter
print_status "Instalando dependencias de Flutter..."
flutter pub get

# Verificar configuración de Flutter
print_status "Verificando configuración de Flutter..."
flutter doctor

# Crear archivo de entorno para Flutter si no existe
if [ ! -f ".env" ]; then
    print_status "Creando archivo de entorno para Flutter..."
    cat > .env << EOF
# API URLs
API_URL_LOCAL=http://localhost:8000
API_URL_PROD=https://api.zonix-eats.com

# Google Maps API Key
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here

# WebSocket Configuration - Laravel Echo Server
WEBSOCKET_URL_LOCAL=ws://localhost:6001
WEBSOCKET_URL_PROD=wss://echo.zonix-eats.com
ECHO_APP_ID=zonix-eats-app
ECHO_KEY=zonix-eats-key
ENABLE_WEBSOCKETS=true

# Firebase Configuration
FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id
EOF
    print_warning "Por favor edita el archivo .env con tus configuraciones"
fi

print_success "Frontend Flutter configurado"

# Mostrar información de conexión
echo ""
print_success "🎉 Entorno de desarrollo iniciado correctamente!"
echo ""
echo "📱 Frontend Flutter: http://localhost:3000"
echo "🔧 Backend Laravel: http://localhost:8000"
echo "📡 WebSocket Server: ws://localhost:6001"
echo "🗄️  Redis Server: localhost:6379"
echo ""
echo "📋 Comandos útiles:"
echo "  • Ver logs de Laravel: tail -f ../zonix-eats-back/storage/logs/laravel.log"
echo "  • Ver logs de Echo Server: tail -f ../zonix-eats-back/echo-server.log"
echo "  • Detener servicios: ./stop_development.sh"
echo "  • Reiniciar servicios: ./restart_development.sh"
echo ""
print_warning "Recuerda editar los archivos .env con tus configuraciones específicas"
echo ""

# Iniciar Flutter en modo desarrollo
print_status "Iniciando Flutter en modo desarrollo..."
print_warning "Presiona Ctrl+C para detener todos los servicios"
flutter run --web-port=3000 