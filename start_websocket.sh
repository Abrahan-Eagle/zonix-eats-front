#!/bin/bash

# Script para iniciar Laravel Echo Server para ZONIX-EATS
# Autor: ZONIX-EATS Team
# Fecha: $(date)

echo "🚀 Iniciando Laravel Echo Server para ZONIX-EATS..."

# Verificar si Node.js está instalado
if ! command -v node &> /dev/null; then
    echo "❌ Error: Node.js no está instalado"
    echo "Por favor instala Node.js desde https://nodejs.org/"
    exit 1
fi

# Verificar si laravel-echo-server está instalado
if ! command -v laravel-echo-server &> /dev/null; then
    echo "📦 Instalando laravel-echo-server..."
    npm install -g laravel-echo-server
fi

# Verificar si el archivo de configuración existe
if [ ! -f "laravel-echo-server.json" ]; then
    echo "❌ Error: No se encontró laravel-echo-server.json"
    echo "Por favor asegúrate de estar en el directorio correcto"
    exit 1
fi

# Verificar si el puerto está disponible
PORT=$(grep -o '"port": "[^"]*"' laravel-echo-server.json | cut -d'"' -f4)
if [ -z "$PORT" ]; then
    PORT=6001
fi

if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️  Advertencia: El puerto $PORT ya está en uso"
    echo "Deteniendo proceso anterior..."
    pkill -f "laravel-echo-server"
    sleep 2
fi

echo "🔧 Configuración:"
echo "   - Puerto: $PORT"
echo "   - Modo: Desarrollo"
echo "   - Protocolo: HTTP"

# Iniciar Laravel Echo Server
echo "🔄 Iniciando servidor..."
laravel-echo-server start

echo "✅ Laravel Echo Server iniciado correctamente"
echo "📡 Escuchando en: http://localhost:$PORT"
echo "🔗 Para detener el servidor, presiona Ctrl+C" 