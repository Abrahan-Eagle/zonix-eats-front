/// Cadenas de la app para i18n. Por ahora solo español; luego se puede
/// conectar a flutter_localizations o intl.
class AppStrings {
  AppStrings._();

  // Detalle de orden
  static const String orderDetailTitle = 'Detalle de orden';
  static const String orderNotFound = 'Orden no encontrada';
  static const String retry = 'Reintentar';
  static const String receiptDetailTitle = 'Detalle del Recibo';
  static const String deliveryTracking = 'Seguimiento de entrega';
  static const String waitingDeliveryLocation = 'Esperando ubicación del repartidor...';
  static const String openInGoogleMaps = 'Ver en Google Maps';
  static const String downloadPdf = 'Descargar PDF';
  static const String generating = 'Generando...';
  static const String uploadPaymentProof = 'Subir comprobante de pago';
  static const String cancelOrder = 'Cancelar orden';
  static const String cancelOrderConfirmTitle = 'Cancelar orden';
  static const String no = 'No';
  static const String yesCancel = 'Sí, cancelar';
  static const String orderCancelled = 'Orden cancelada';
  static const String paymentProofUploaded = 'Comprobante subido correctamente';
  static const String enterPaymentMethodAndRef = 'Debes ingresar método de pago y número de referencia';
  static const String idCopied = 'ID copiado al portapapeles';
  static const String openingReceipt = 'Abriendo recibo...';
  static const String couldNotOpenLink = 'No se pudo abrir el enlace. Generando PDF...';
  static const String pdfReady = 'PDF listo para guardar o compartir';
  static const String errorGeneratingPdf = 'Error al generar el PDF';
  static const String pendingPayment = 'Pendiente de pago';
  static const String uploadProof = 'Subir comprobante';
  static const String enterPaymentData = 'Ingresa los datos del pago realizado:';

  // Resumen / recibo
  static const String summary = 'RESUMEN';
  static const String subtotal = 'Subtotal';
  static const String deliveryFee = 'Tarifa de entrega';
  static const String tax = 'Impuestos';
  static const String serviceFee = 'Tarifa de servicio';
  static const String total = 'Total';
  static const String paymentMethod = 'Método de pago';
  static const String deliveryAddress = 'Dirección de entrega';
  static const String commerce = 'Comercio';
  static const String orderId = 'ORDEN ID: ';

  // PDF Recibo (labels)
  static const String receiptTitle = 'RECIBO';
  static const String receiptNumberLabel = 'N.º de recibo';
  static const String issueDateLabel = 'Fecha de emisión';
  static const String clientDataLabel = 'Datos del cliente';
  static const String clientLabel = 'Cliente';
  static const String paymentMethodLabelPdf = 'Método de pago';
  static const String quantityCol = 'Cant.';
  static const String descriptionCol = 'Descripción';
  static const String unitPriceCol = 'Precio unit.';
  static const String subtotalCol = 'Subtotal';
  static const String shippingCostLabel = 'Costo de envío';
  static const String taxLabelIva = 'Impuestos (IVA 16%)';
  static const String totalFinalLabel = 'TOTAL FINAL';
  static const String thanksZonixEats = '¡Gracias por elegir ZonixEATS!';
  static const String footerSupportText = 'Esperamos que disfrutes tu pedido. Guarda este recibo. Para soporte, visita zonixeats.com/support.';
  static const String receiptHashLabel = 'Recibo #';
  static const String scanToVerify = 'Escanea para verificar';
  static const String zonixEatsTagline = 'INTERSTELLAR GOURMET DELIVERY';
  // Métodos de pago (recibo)
  static const String paymentCash = 'Efectivo';
  static const String paymentTransfer = 'Transferencia';
  static const String paymentCard = 'Tarjeta';
  static const String paymentMobile = 'Pago móvil';
}
