// Complete DHA location hierarchy for all 5 cities.
// Structure: City → Phase → List of Sectors
// This is the single source of truth for all dropdown/selection options
// in the cascading search UI.

const List<String> dhaCities = [
  'Islamabad',
  'Karachi',
  'Lahore',
  'Peshawar',
  'Multan',
];

const Map<String, List<String>> dhaPhases = {
  'Islamabad': [
    'Phase 1',
    'Phase 2',
    'Phase 2 Extension',
    'Phase 3',
    'Phase 4',
    'Phase 5',
  ],
  'Karachi': [
    'Phase 1',
    'Phase 2',
    'Phase 4',
    'Phase 5',
    'Phase 6',
    'Phase 7',
    'Phase 8',
    'Phase 9 (Prism)',
  ],
  'Lahore': [
    'Phase 1',
    'Phase 2',
    'Phase 3',
    'Phase 4',
    'Phase 5',
    'Phase 6',
    'Phase 7',
    'Phase 8',
    'Phase 9 (Prism)',
    'Phase 10',
    'Phase 11 (Rahbar)',
    'Phase 12',
  ],
  'Peshawar': [
    'Phase 1',
    'Phase 2',
  ],
  'Multan': [
    'Phase 1 (Midcity)',
  ],
};

const Map<String, Map<String, List<String>>> dhaSectors = {
  'Islamabad': {
    'Phase 1': ['Sector A', 'Sector B', 'Sector C', 'Sector D', 'Sector E', 'Sector F'],
    'Phase 2': ['Sector A', 'Sector B', 'Sector C', 'Sector D', 'Sector E', 'Sector F', 'Sector G', 'Sector H', 'Sector J', 'Sector K'],
    'Phase 2 Extension': ['Sector A', 'Sector B', 'Sector C'],
    'Phase 3': ['Sector A', 'Sector B', 'Sector C', 'Sector D', 'Sector E'],
    'Phase 4': ['Sector A', 'Sector B', 'Sector C'],
    'Phase 5': ['Sector A', 'Sector B'],
  },
  'Karachi': {
    'Phase 1': ['Block A', 'Block B', 'Block C', 'Block D', 'Block E', 'Block F', 'Block G', 'Block H'],
    'Phase 2': ['Block A', 'Block B', 'Block C', 'Block D', 'Block E', 'Block F'],
    'Phase 4': ['Block A', 'Block B', 'Block C', 'Block D'],
    'Phase 5': ['Block A', 'Block B', 'Block C', 'Block D', 'Block E', 'Block F', 'Block G', 'Block H', 'Block J', 'Block K'],
    'Phase 6': ['Block A', 'Block B', 'Block C', 'Block D', 'Block E', 'Block F', 'Block G', 'Block H', 'Block J', 'Block K', 'Block L', 'Block M', 'Block N'],
    'Phase 7': ['Block A', 'Block B', 'Block C', 'Block D', 'Block E', 'Block F', 'Block G', 'Block H', 'Block J', 'Block K'],
    'Phase 8': ['Block A', 'Block B', 'Block C', 'Block D', 'Block E', 'Block F'],
    'Phase 9 (Prism)': ['Block A', 'Block B', 'Block C', 'Block D', 'Block E', 'Block F', 'Block G', 'Block H'],
  },
  'Lahore': {
    'Phase 1': ['Sector A', 'Sector B', 'Sector C', 'Sector D', 'Sector E', 'Sector F', 'Sector G', 'Sector H', 'Sector J', 'Sector K', 'Sector L', 'Sector M'],
    'Phase 2': ['Sector A', 'Sector B', 'Sector C', 'Sector D', 'Sector E', 'Sector F', 'Sector G', 'Sector H', 'Sector J', 'Sector K'],
    'Phase 3': ['Sector A', 'Sector B', 'Sector C', 'Sector D', 'Sector E', 'Sector F', 'Sector G', 'Sector H', 'Sector J'],
    'Phase 4': ['Sector A', 'Sector B', 'Sector C', 'Sector D', 'Sector E', 'Sector F', 'Sector G', 'Sector H'],
    'Phase 5': ['Sector A', 'Sector B', 'Sector C', 'Sector D', 'Sector E', 'Sector F'],
    'Phase 6': ['Sector A', 'Sector B', 'Sector C', 'Sector D', 'Sector E', 'Sector F', 'Sector G', 'Sector H', 'Sector J', 'Sector K'],
    'Phase 7': ['Sector W', 'Sector X', 'Sector Y', 'Sector Z'],
    'Phase 8': ['Block A', 'Block B', 'Block C', 'Block D', 'Block E'],
    'Phase 9 (Prism)': ['Sector A', 'Sector B', 'Sector C', 'Sector D', 'Sector E', 'Sector F', 'Sector G', 'Sector H', 'Sector J'],
    'Phase 10': ['Sector A', 'Sector B', 'Sector C'],
    'Phase 11 (Rahbar)': ['Sector A', 'Sector B', 'Sector C', 'Sector D'],
    'Phase 12': ['Sector A', 'Sector B'],
  },
  'Peshawar': {
    'Phase 1': ['Sector A', 'Sector B', 'Sector C', 'Sector D', 'Sector E', 'Sector F'],
    'Phase 2': ['Sector A', 'Sector B', 'Sector C', 'Sector D'],
  },
  'Multan': {
    'Phase 1 (Midcity)': ['Block A', 'Block B', 'Block C', 'Block D', 'Block E', 'Block F', 'Block G', 'Block H'],
  },
};

/// Returns phases for a given city, or empty list if city not found.
List<String> getPhasesForCity(String city) => dhaPhases[city] ?? [];

/// Returns sectors for a given city+phase combo, or empty list if not found.
List<String> getSectorsForPhase(String city, String phase) =>
    dhaSectors[city]?[phase] ?? [];
