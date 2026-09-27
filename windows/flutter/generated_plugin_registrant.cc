//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <flutter_classic_bluetooth/flutter_classic_bluetooth_plugin_c_api.h>
#include <record_windows/record_windows_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  FlutterClassicBluetoothPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterClassicBluetoothPluginCApi"));
  RecordWindowsPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("RecordWindowsPluginCApi"));
}
