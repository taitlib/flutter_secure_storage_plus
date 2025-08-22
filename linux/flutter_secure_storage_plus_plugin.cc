#include "include/flutter_secure_storage_plus/flutter_secure_storage_plus_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>

#include "flutter_secure_storage_plus_plugin_private.h"

#define FLUTTER_SECURE_STORAGE_PLUS_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), flutter_secure_storage_plus_plugin_get_type(), \
                              FlutterSecureStoragePlusPlugin))

struct _FlutterSecureStoragePlusPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(FlutterSecureStoragePlusPlugin, flutter_secure_storage_plus_plugin, g_object_get_type())


#include <map>
#include <string>

static std::map<std::string, std::string> g_memory_store;

// Called when a method call is received from Flutter.
static void flutter_secure_storage_plus_plugin_handle_method_call(
    FlutterSecureStoragePlusPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "getPlatformVersion") == 0) {
    response = get_platform_version();
  } else if (strcmp(method, "write") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    const gchar* key = fl_value_get_string(fl_value_lookup_string(args, "key"));
    const gchar* value = fl_value_get_string(fl_value_lookup_string(args, "value"));
    if (key && value) {
      g_memory_store[key] = value;
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID_ARGUMENT", "Key and value are required", nullptr));
    }
  } else if (strcmp(method, "read") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    const gchar* key = fl_value_get_string(fl_value_lookup_string(args, "key"));
    if (key) {
      auto it = g_memory_store.find(key);
      if (it != g_memory_store.end()) {
        g_autoptr(FlValue) result = fl_value_new_string(it->second.c_str());
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
      } else {
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
      }
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID_ARGUMENT", "Key is required", nullptr));
    }
  } else if (strcmp(method, "delete") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    const gchar* key = fl_value_get_string(fl_value_lookup_string(args, "key"));
    if (key) {
      g_memory_store.erase(key);
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID_ARGUMENT", "Key is required", nullptr));
    }
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

FlMethodResponse* get_platform_version() {
  struct utsname uname_data = {};
  uname(&uname_data);
  g_autofree gchar *version = g_strdup_printf("Linux %s", uname_data.version);
  g_autoptr(FlValue) result = fl_value_new_string(version);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static void flutter_secure_storage_plus_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(flutter_secure_storage_plus_plugin_parent_class)->dispose(object);
}

static void flutter_secure_storage_plus_plugin_class_init(FlutterSecureStoragePlusPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = flutter_secure_storage_plus_plugin_dispose;
}

static void flutter_secure_storage_plus_plugin_init(FlutterSecureStoragePlusPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  FlutterSecureStoragePlusPlugin* plugin = FLUTTER_SECURE_STORAGE_PLUS_PLUGIN(user_data);
  flutter_secure_storage_plus_plugin_handle_method_call(plugin, method_call);
}

void flutter_secure_storage_plus_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  FlutterSecureStoragePlusPlugin* plugin = FLUTTER_SECURE_STORAGE_PLUS_PLUGIN(
      g_object_new(flutter_secure_storage_plus_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "flutter_secure_storage_plus",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
