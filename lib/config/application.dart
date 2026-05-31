import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/current_user.dart';

class Application {
  static late String apiBaseURL;
  static late String graphQLURL;

  static Future<void> init() async {
    apiBaseURL = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080';
    graphQLURL = '$apiBaseURL/graphql';

    await CurrentUser.instance.init();
  }
}
