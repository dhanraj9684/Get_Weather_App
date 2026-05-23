import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController cityController = TextEditingController();

  Map<String, dynamic>? result;
  List<List<String>> citiesData = [];

  @override
  void initState() {
    super.initState();
    loadCSV();
  }

  Future<void> loadCSV() async {
    final raw = await rootBundle.loadString('assets/data/cities.csv');
    final list = const CsvToListConverter().convert(raw);

    citiesData = list
        .skip(1)
        .map((e) => e.map((x) => x.toString()).toList())
        .toList();
  }

  String clean(String s) {
    return s.replaceAll('"', '').toLowerCase().trim();
  }

  Map<String, double>? getLatLon(String input) {
    String inputClean = clean(input);

    for (var row in citiesData) {
      if (row.length < 6) continue;

      String city = clean(row[1]);

      if (city == inputClean) {
        return {
          "lat": double.parse(row[4]),
          "lon": double.parse(row[5]),
        };
      }

      if (row[2].isNotEmpty) {
        List<String> altNames = clean(row[2]).split(';');

        if (altNames.contains(inputClean)) {
          return {
            "lat": double.parse(row[4]),
            "lon": double.parse(row[5]),
          };
        }
      }
    }
    return null;
  }

  Future<void> fetchData(String cityName) async {
    final coords = getLatLon(cityName);

    if (coords == null) {
      setState(() {
        result = {"error": "City not found"};
      });
      return;
    }

    final url = Uri.parse(
        "https://api.open-meteo.com/v1/forecast?latitude=${coords["lat"]}&longitude=${coords["lon"]}&current=temperature_2m,apparent_temperature");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        result = data["current"];
      });
    } else {
      setState(() {
        result = {"error": "API failed"};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Get Current Weather Information ')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 250,
                child: TextField(
                  controller: cityController,
                  decoration: InputDecoration(labelText: "Enter City"),
                  onSubmitted: (value) {
                    fetchData(value);
                  },
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(border: Border.all()),
                child: result == null
                    ? Text("No data")
                    : Text(result.toString()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}