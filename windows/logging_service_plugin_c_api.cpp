#include "include/logging_service/logging_service_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "logging_service_plugin.h"

void LoggingServicePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  logging_service::LoggingServicePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
