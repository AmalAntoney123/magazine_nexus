import 'package:appwrite/appwrite.dart';

class AppwriteService {
  static const String projectId = '<676fc20b003ccf154826>';
  static const String endpoint = 'https://cloud.appwrite.io/v1';

  static final Client client =
      Client().setEndpoint(endpoint).setProject(projectId);

  static final Account account = Account(client);
  static final Databases databases = Databases(client);
}
