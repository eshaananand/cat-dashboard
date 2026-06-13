import 'package:flutter/material.dart';

import 'app/cat_prep_app.dart';
import 'prep_store.dart';

export 'app/cat_prep_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await PrepStore.load();
  runApp(CatPrepApp(store: store));
}
