import 'advanced_user_translations.dart';

class TranslationHelper {
  static String _currentLanguage = 'es';

  static void setLanguage(String language) {
    _currentLanguage = language;
  }

  static String getCurrentLanguage() {
    return _currentLanguage;
  }

  static String t(String key) {
    return AdvancedUserTranslations.getText(key, _currentLanguage);
  }

  static String tf(String key) {
    return AdvancedUserTranslations.getTextWithFallback(key, _currentLanguage);
  }

  // Helper methods for common translations
  static String getActivityHistoryTitle() => t('activity_history_title');
  static String getDataExportTitle() => t('data_export_title');
  static String getPrivacySettingsTitle() => t('privacy_settings_title');
  static String getAccountDeletionTitle() => t('account_deletion_title');
  
  static String getLoadingText() => t('common_loading');
  static String getErrorText() => t('common_error');
  static String getSuccessText() => t('common_success');
  static String getCancelText() => t('common_cancel');
  static String getSaveText() => t('common_save');
  static String getConfirmText() => t('common_confirm');
  
  static String getActivityTypeText(String type) {
    switch (type) {
      case 'login':
        return t('activity_type_login');
      case 'order_placed':
        return t('activity_type_order_placed');
      case 'order_cancelled':
        return t('activity_type_order_cancelled');
      case 'profile_updated':
        return t('activity_type_profile_updated');
      case 'review_posted':
        return t('activity_type_review_posted');
      default:
        return type;
    }
  }
  
  static String getDataTypeText(String type) {
    switch (type) {
      case 'profile':
        return t('data_type_profile');
      case 'orders':
        return t('data_type_orders');
      case 'activity':
        return t('data_type_activity');
      case 'reviews':
        return t('data_type_reviews');
      case 'addresses':
        return t('data_type_addresses');
      case 'notifications':
        return t('data_type_notifications');
      default:
        return type;
    }
  }
  
  static String getExportFormatText(String format) {
    switch (format) {
      case 'json':
        return t('export_format_json');
      case 'csv':
        return t('export_format_csv');
      case 'pdf':
        return t('export_format_pdf');
      default:
        return format.toUpperCase();
    }
  }
  
  static String getExportStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return t('export_status_completed');
      case 'processing':
        return t('export_status_processing');
      case 'failed':
        return t('export_status_failed');
      case 'pending':
        return t('export_status_pending');
      default:
        return status;
    }
  }
  
  static String getDeletionReasonText(String reason) {
    switch (reason) {
      case 'Ya no uso la aplicación':
        return t('deletion_reason_no_use');
      case 'Problemas con el servicio':
        return t('deletion_reason_problems');
      case 'Preocupaciones de privacidad':
        return t('deletion_reason_privacy');
      case 'Creé una nueva cuenta':
        return t('deletion_reason_new_account');
      case 'Otro':
        return t('deletion_reason_other');
      default:
        return reason;
    }
  }
} 