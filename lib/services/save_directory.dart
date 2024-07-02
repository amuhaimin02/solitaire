import 'package:path_provider/path_provider.dart';

class SaveDirectory {
  SaveDirectory._(this.path);

  final String path;

  static Future<SaveDirectory> getInstance() async {
    return SaveDirectory._((await getApplicationDocumentsDirectory()).path);
  }
}
