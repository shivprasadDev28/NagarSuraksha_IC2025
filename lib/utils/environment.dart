class Environment {
  // WAQI API Configuration
  static const String waqiApiToken = '6370d26bbfa89d78a8b247f3afef17ae3a062560';
  static const String waqiBaseUrl = 'https://api.waqi.info/feed';
  
  // Supabase Configuration
  static const String supabaseUrl = 'https://dcwucyqbqxnkyknbutxw.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRjd3VjeXFicXhua3lrbmJ1dHh3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE0MjYwNTcsImV4cCI6MjA3NzAwMjA1N30.nBYaZgb6-qsM1Not-cYqiDamhOfbcbzF0Jw50xXq_34';
  
  // App Configuration
  static const String appName = 'NagarSuraksha';
  static const String appVersion = '1.0.0';
  
  // Cache Configuration
  static const int cacheExpirationMinutes = 10;
  
  // Map Configuration
  static const double defaultLatitude = 28.6139; // Delhi coordinates
  static const double defaultLongitude = 77.2090;
}
