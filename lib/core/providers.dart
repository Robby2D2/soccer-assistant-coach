import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/db/database.dart';

export '../data/db/database.dart';

final dbProvider = Provider<AppDb>((_) => AppDb());
