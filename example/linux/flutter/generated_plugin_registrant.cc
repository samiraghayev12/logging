//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <logging_service/logging_service_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) logging_service_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "LoggingServicePlugin");
  logging_service_plugin_register_with_registrar(logging_service_registrar);
}
