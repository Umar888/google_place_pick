import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SharedPreference {

 readInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if(prefs.getInt(key) == null){
      return null;
    }else{
      return prefs.getInt(key)!;
    }
  }
  Future<String> readIntString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if(prefs.getInt(key) == null){
      return "";
    }else{
      return prefs.getInt(key)!.toString();
    }
  }

  readJson(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if(prefs.getString(key)==null){
      return null;
    }else{
      return json.decode(prefs.getString(key)!);
    }
  }

  saveJson(String key, value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, json.encode(value));
  }

  saveInt(String key, value) async {
    final pref = await SharedPreferences.getInstance();
    pref.setInt(key, value);
  }

  saveString(String key, value) async {
    final pref = await SharedPreferences.getInstance();
    pref.setString(key, value);
  }
  saveBool(String key, value) async {
    final pref = await SharedPreferences.getInstance();
    pref.setBool(key, value);
  }
  Future<String> readString(String key) async {
    final pref = await SharedPreferences.getInstance();
    if(pref.getString(key) != null) {
      return pref.getString(key)??"";
    }
    else{
      return "";
    }
  }
  readBool(String key) async {
    final pref = await SharedPreferences.getInstance();
    if(pref.getBool(key) != null) {
      return pref.getBool(key)??false;
    }
    else{
      return false;
    }
  }

  remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(key);
  }
  clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }
}