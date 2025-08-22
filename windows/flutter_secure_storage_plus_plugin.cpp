#include "flutter_secure_storage_plus_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

namespace flutter_secure_storage_plus {

// static
void FlutterSecureStoragePlusPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "flutter_secure_storage_plus",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<FlutterSecureStoragePlusPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

FlutterSecureStoragePlusPlugin::FlutterSecureStoragePlusPlugin() {}

FlutterSecureStoragePlusPlugin::~FlutterSecureStoragePlusPlugin() {}

void FlutterSecureStoragePlusPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  static std::map<std::string, std::string> memory_store;
  const auto& method = method_call.method_name();
  const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());

  if (method == "getPlatformVersion") {
    std::ostringstream version_stream;
    version_stream << "Windows ";
    if (IsWindows10OrGreater()) {
      version_stream << "10+";
    } else if (IsWindows8OrGreater()) {
      version_stream << "8";
    } else if (IsWindows7OrGreater()) {
      version_stream << "7";
    }
    result->Success(flutter::EncodableValue(version_stream.str()));
  } else if (method == "write") {
    if (args) {
      auto key_it = args->find(flutter::EncodableValue("key"));
      auto value_it = args->find(flutter::EncodableValue("value"));
      if (key_it != args->end() && value_it != args->end()) {
        std::string key = std::get<std::string>(key_it->second);
        std::string value = std::get<std::string>(value_it->second);
        memory_store[key] = value;
        result->Success();
        return;
      }
    }
    result->Error("INVALID_ARGUMENT", "Key and value are required", nullptr);
  } else if (method == "read") {
    if (args) {
      auto key_it = args->find(flutter::EncodableValue("key"));
      if (key_it != args->end()) {
        std::string key = std::get<std::string>(key_it->second);
        auto found = memory_store.find(key);
        if (found != memory_store.end()) {
          result->Success(flutter::EncodableValue(found->second));
        } else {
          result->Success();
        }
        return;
      }
    }
    result->Error("INVALID_ARGUMENT", "Key is required", nullptr);
  } else if (method == "delete") {
    if (args) {
      auto key_it = args->find(flutter::EncodableValue("key"));
      if (key_it != args->end()) {
        std::string key = std::get<std::string>(key_it->second);
        memory_store.erase(key);
        result->Success();
        return;
      }
    }
    result->Error("INVALID_ARGUMENT", "Key is required", nullptr);
  } else {
    result->NotImplemented();
  }
}

}  // namespace flutter_secure_storage_plus
