const Map<String, List<Map<String, String>>> logTemplates = {
  'methane_hourly': [
    {'label': 'Temperature (°F)', 'key': 'temperature'},
    {'label': 'Pressure (psi)', 'key': 'pressure'},
    {'label': 'H2S (ppm)', 'key': 'h2s'},
    {'label': 'LEL (%)', 'key': 'lel'},
  ],
  'benzene_12hr': [
    {'label': 'Benzene (ppm)', 'key': 'benzene'},
    {'label': 'Wind Direction', 'key': 'windDirection'},
  ],
  'pentane_hourly': [
    {'label': 'Temp (°F)', 'key': 'temperature'},
    {'label': 'LEL (%)', 'key': 'lel'},
    {'label': 'Ambient H2S (ppm)', 'key': 'ambientH2S'},
    {'label': 'Ambient Benzene (ppm)', 'key': 'ambientBenzene'},
  ],
};