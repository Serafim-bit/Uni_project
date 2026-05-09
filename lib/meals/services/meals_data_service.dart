import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uni_project/meals/models/category.dart';
import 'package:uni_project/meals/models/meal.dart';

class DataService {
  static Future<List<Category>> loadCategories() async {
    final String response = await rootBundle.loadString('assets/data/categories.json');
    final List<dynamic> data = json.decode(response);
    
    return data.map((json) => Category(
      id: json['id'],
      title: json['title'],
      color: _getColorFromName(json['color']),
    )).toList();
  }

  static Future<List<Meal>> loadMeals() async {
    final String response = await rootBundle.loadString('assets/data/meals.json');
    final List<dynamic> data = json.decode(response);
    
    return data.map((json) => Meal(
      id: json['id'],
      categories: List<String>.from(json['categories']),
      title: json['title'],
      imageUrl: json['imageUrl'],
      ingredients: List<String>.from(json['ingredients']),
      steps: List<String>.from(json['steps']),
      duration: json['duration'],
      complexity: _getComplexityFromString(json['complexity']),
      affordability: _getAffordabilityFromString(json['affordability']),
      isGlutenFree: json['isGlutenFree'],
      isLactoseFree: json['isLactoseFree'],
      isVegan: json['isVegan'],
      isVegetarian: json['isVegetarian'],
    )).toList();
  }

  static Color _getColorFromName(String colorName) {
    switch (colorName) {
      case 'purple':
        return Colors.purple;
      case 'red':
        return Colors.red;
      case 'orange':
        return Colors.orange;
      case 'amber':
        return Colors.amber;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'lightBlue':
        return Colors.lightBlue;
      case 'lightGreen':
        return Colors.lightGreen;
      case 'pink':
        return Colors.pink;
      case 'teal':
        return Colors.teal;
      default:
        return Colors.orangeAccent;
    }
  }

  static Complexity _getComplexityFromString(String complexity) {
    switch (complexity) {
      case 'simple':
        return Complexity.simple;
      case 'challenging':
        return Complexity.challenging;
      case 'hard':
        return Complexity.hard;
      default:
        return Complexity.simple;
    }
  }

  static Affordability _getAffordabilityFromString(String affordability) {
    switch (affordability) {
      case 'affordable':
        return Affordability.affordable;
      case 'pricey':
        return Affordability.pricey;
      case 'luxurious':
        return Affordability.luxurious;
      default:
        return Affordability.affordable;
    }
  }
}