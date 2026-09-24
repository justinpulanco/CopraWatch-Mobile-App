/// Maps ML classification to descriptive moisture status
class MoistureMapper {
  /// Convert ML classification to moisture status
  static String classificationToMoistureStatus(String classification) {
    switch (classification.toLowerCase()) {
      case 'under-dried':
      case 'underdr':
        return 'too_wet'; // Under-dried = too much moisture = too wet
      case 'optimally-dried':
      case 'optimal':
        return 'perfect'; // Optimal = just right
      case 'over-dried':
      case 'overdr':
        return 'too_dry'; // Over-dried = too little moisture = too dry
      default:
        return 'unknown';
    }
  }

  /// Get display label in Tagalog with English translation
  static String getMoistureDisplayTl(String moistureStatus) {
    switch (moistureStatus) {
      case 'too_wet':
        return 'Basa-basa (Wet / Under-Dried)';
      case 'slightly_squishy':
        return 'Kaunting Lata (Slightly Squishy)';
      case 'perfect':
        return 'Tuyo (Perfectly-Dried)';
      case 'slightly_dry':
        return 'Medyo Tuyo Na (Slightly Dry)';
      case 'too_dry':
        return 'Sunog (Over-Dried / Burned)';
      default:
        return 'Hindi Alam (Unknown)';
    }
  }

  /// Get display label in English with Tagalog translation
  static String getMoistureDisplayEn(String moistureStatus) {
    switch (moistureStatus) {
      case 'too_wet':
        return 'Basa-basa (Wet / Under-Dried)';
      case 'slightly_squishy':
        return 'Slightly Squishy (Kaunting Lata)';
      case 'perfect':
        return 'Tuyo (Perfectly-Dried)';
      case 'slightly_dry':
        return 'Slightly Dry (Medyo Tuyo Na)';
      case 'too_dry':
        return 'Sunog (Over-Dried / Burned)';
      default:
        return 'Unknown (Hindi Alam)';
    }
  }

  /// Get color hex for moisture status
  static String getMoistureColor(String moistureStatus) {
    switch (moistureStatus) {
      case 'too_wet':
        return '#FF6B6B'; // Red - not ready
      case 'slightly_squishy':
        return '#FFA500'; // Orange - almost there
      case 'perfect':
        return '#4CAF50'; // Green - ready to harvest
      case 'slightly_dry':
        return '#8B7355'; // Brown - acceptable
      case 'too_dry':
        return '#3E2723'; // Dark Brown - burned
      default:
        return '#9E9E9E'; // Gray - unknown
    }
  }

  /// Get icon representation
  static String getMoistureIcon(String moistureStatus) {
    switch (moistureStatus) {
      case 'too_wet':
        return '💧'; // Water droplet
      case 'slightly_squishy':
        return '🤏'; // Pinching hand
      case 'perfect':
        return '✅'; // Check mark
      case 'slightly_dry':
        return '🍂'; // Leaves
      case 'too_dry':
        return '🔥'; // Fire
      default:
        return '❓'; // Question mark
    }
  }
}
