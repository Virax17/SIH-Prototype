//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <flutter_classic_bluetooth/flutter_classic_bluetooth_plugin_c_api.h>
#include <flutter_tts/flutter_tts_plugin.h>
#include <permission_handler_windows/permission_handler_windows_plugin.h>
#include <vosk_flutter/vosk_flutter_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  FlutterClassicBluetoothPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterClassicBluetoothPluginCApi"));
  FlutterTtsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterTtsPlugin"));
  PermissionHandlerWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PermissionHandlerWindowsPlugin"));
  VoskFlutterPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("VoskFlutterPlugin"));
}
