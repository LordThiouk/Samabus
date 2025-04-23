class AppConfig {
  // Supabase configuration
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://your-project-url.supabase.co');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'your-anon-key');
  
  // Payment gateway configuration
  static const String paydunyaApiKey = String.fromEnvironment('PAYDUNYA_API_KEY', defaultValue: '');
  static const String cinetpayApiKey = String.fromEnvironment('CINETPAY_API_KEY', defaultValue: '');
  
  // App settings
  static const int offlineDataRetentionHours = 24;
  static const int personalDataRetentionDays = 30;
  static const double platformCommissionRate = 0.05; // 5%
}
