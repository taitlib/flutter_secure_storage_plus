#include "include/flutter_secure_storage_plus/flutter_secure_storage_plus_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_secure_storage_plus_plugin.h"

void FlutterSecureStoragePlusPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_secure_storage_plus::FlutterSecureStoragePlusPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
