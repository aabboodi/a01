import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestClassroomPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();

    return cameraStatus.isGranted && microphoneStatus.isGranted;
  }
}
