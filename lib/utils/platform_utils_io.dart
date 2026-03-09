import 'dart:io';
import 'package:sqflite_sqlcipher/sqflite.dart' as sqflite;

Future<String> getDatabasesPath() => sqflite.getDatabasesPath();

bool get isMacOS => Platform.isMacOS;

Future<bool> fileExists(String path) => File(path).exists();

Future<void> deleteDatabase(String path) => sqflite.deleteDatabase(path);
