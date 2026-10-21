import 'dart:convert';
import 'dart:io';

import 'package:aerostar_edge/mockData/catalog_loader.dart';

/// Loads the spreadsheet catalogue straight from assets/data (no asset bundle
/// needed), the same way main() does through rootBundle.
void loadCatalogFromDisk() {
  List<Map<String, dynamic>> read(String name) =>
      (jsonDecode(File('assets/data/$name').readAsStringSync()) as List).cast<Map<String, dynamic>>();
  installCatalog(read('jobs.json'), read('courses.json'));
}
