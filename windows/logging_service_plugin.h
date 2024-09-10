#ifndef FLUTTER_PLUGIN_LOGGING_SERVICE_PLUGIN_H_
#define FLUTTER_PLUGIN_LOGGING_SERVICE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace logging_service {

class LoggingServicePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  LoggingServicePlugin();

  virtual ~LoggingServicePlugin();

  // Disallow copy and assign.
  LoggingServicePlugin(const LoggingServicePlugin&) = delete;
  LoggingServicePlugin& operator=(const LoggingServicePlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace logging_service

#endif  // FLUTTER_PLUGIN_LOGGING_SERVICE_PLUGIN_H_
