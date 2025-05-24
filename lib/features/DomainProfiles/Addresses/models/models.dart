class Country {
  final int id;
  final String name;
  final List<StateModel> states;

  const Country({
    required this.id,
    required this.name,
    required this.states,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    // Manejo seguro de la lista
    var statesList = (json['states'] as List<dynamic>? ?? [])
        .map((state) => StateModel.fromJson(state as Map<String, dynamic>))
        .toList();

    return Country(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      states: statesList,
    );
  }
}

class StateModel {
  final int id;
  final String name;
  final List<City> cities;

  const StateModel({
    required this.id,
    required this.name,
    required this.cities,
  });

  factory StateModel.fromJson(Map<String, dynamic> json) {
    var citiesList = (json['cities'] as List<dynamic>? ?? [])
        .map((city) => City.fromJson(city as Map<String, dynamic>))
        .toList();

    return StateModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      cities: citiesList,
    );
  }
}


class City {
  final int id;
  final String name;

  const City({
    required this.id,
    required this.name,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown',
    );
  }
}
