#include "./ao.h"
#include <stdio.h>
#include <stdlib.h>
#include "vendor/quickjs/quickjs.h"

/* Handles the processing of a message within a specific environment.
 *
 * @param msg A string representing the message to be processed.
 * @param env A string representing the environment settings to be used for processing the message.
 * @return A pointer to a string indicating the result of the message processing. This may include
 *         a response message or an indication of success or failure. The caller may need to handle
 *         or display this result according to the application's requirements.
 */

// Helper function to create our sandboxed environment
static JSValue create_ao_object(JSContext *ctx) {
    JSValue ao_obj = JS_NewObject(ctx);
    
    // Add ao.send wrapper
    JS_SetPropertyStr(ctx, ao_obj, "send", JS_NewCFunction(ctx, js_ao_send, "send", 1));
    
    // Add ao.log wrapper
    JS_SetPropertyStr(ctx, ao_obj, "log", JS_NewCFunction(ctx, js_ao_log, "log", 1));
    
    return ao_obj;
}

// Module loader callback
static JSModuleDef *js_module_loader(JSContext *ctx, const char *module_name, void *opaque) {
    // Read the module file content
    const char *module_source = ao_load_module(module_name); // You'd need to implement this
    if (!module_source) {
        JS_ThrowReferenceError(ctx, "Could not load module '%s'", module_name);
        return NULL;
    }

    // Compile the module
    JSValue func_val = JS_Eval(ctx, module_source, strlen(module_source),
                              module_name, JS_EVAL_TYPE_MODULE | JS_EVAL_FLAG_COMPILE_ONLY);
    
    if (JS_IsException(func_val))
        return NULL;

    // Create and initialize the module
    JSModuleDef *m = JS_VALUE_GET_PTR(func_val);
    JS_FreeValue(ctx, func_val);
    
    return m;
}

// Initialize QuickJS runtime and context with sandbox
static JSContext* init_js_context() {
    JSRuntime *rt = JS_NewRuntime();
    if (!rt) return NULL;
    
    // Set memory limits
    JS_SetMemoryLimit(rt, 50 * 1024 * 1024); // 50MB limit
    JS_SetMaxStackSize(rt, 1024 * 1024); // 1MB stack limit
    
    JSContext *ctx = JS_NewContext(rt);
    if (!ctx) {
        JS_FreeRuntime(rt);
        return NULL;
    }
    
    // Create global object
    JSValue global = JS_GetGlobalObject(ctx);
    
    // Add our sandboxed 'ao' object
    JSValue ao_obj = create_ao_object(ctx);
    JS_SetPropertyStr(ctx, global, "ao", ao_obj);
    
    // Remove unsafe globals
    JS_DeletePropertyStr(ctx, global, "Function");
    JS_DeletePropertyStr(ctx, global, "eval");
    JS_DeletePropertyStr(ctx, global, "fetch");
    JS_DeletePropertyStr(ctx, global, "XMLHttpRequest");
    JS_DeletePropertyStr(ctx, global, "WebSocket");
    JS_DeletePropertyStr(ctx, global, "require");
    JS_DeletePropertyStr(ctx, global, "process");
    JS_DeletePropertyStr(ctx, global, "fs");
    
    JS_FreeValue(ctx, global);

    // Register the module loader
    JS_SetModuleLoaderFunc(rt, NULL, js_module_loader, NULL);
    
    return ctx;
}

// Wrapper for ao.send
static JSValue js_ao_send(JSContext *ctx, JSValueConst this_val, 
                         int argc, JSValueConst *argv) {
    if (argc < 1)
        return JS_EXCEPTION;
        
    const char *msg = JS_ToCString(ctx, argv[0]);
    if (!msg)
        return JS_EXCEPTION;
        
    char *result = ao_send(msg);
    JS_FreeCString(ctx, msg);
    
    JSValue ret = JS_NewString(ctx, result);
    free(result);
    return ret;
}

// Wrapper for ao.log
static JSValue js_ao_log(JSContext *ctx, JSValueConst this_val,
                        int argc, JSValueConst *argv) {
    if (argc < 1)
        return JS_UNDEFINED;
        
    const char *msg = JS_ToCString(ctx, argv[0]);
    if (!msg)
        return JS_EXCEPTION;
        
    ao_log(msg);
    JS_FreeCString(ctx, msg);
    return JS_UNDEFINED;
}

const char *handle(const char *msg, const char *env) {
    // Initialize ao environment
    ao_init(env);
    
    // Initialize JS context
    JSContext *ctx = init_js_context();
    if (!ctx) {
        ao_log("Failed to initialize JavaScript context");
        return "{\"error\": \"Failed to initialize JavaScript context\"}";
    }
    
    // Parse the incoming message
    cJSON *msgJson = cJSON_Parse(msg);
    if (!msgJson) {
        JS_FreeContext(ctx);
        JS_FreeRuntime(JS_GetRuntime(ctx));
        ao_log("Failed to parse message JSON");
        return "{\"error\": \"Failed to parse message JSON\"}";
    }
    
    // Get the Data field containing JavaScript code
    const char *code = cJSON_GetStringValue(
        cJSON_GetObjectItemCaseSensitive(msgJson, "Data")
    );
    
    if (!code) {
        cJSON_Delete(msgJson);
        JS_FreeContext(ctx);
        JS_FreeRuntime(JS_GetRuntime(ctx));
        ao_log("No JavaScript code found in Data field");
        return "{\"error\": \"No JavaScript code found in Data field\"}";
    }
    
    // Evaluate as module if code starts with import/export
    int eval_flags = JS_EVAL_TYPE_GLOBAL;
    if (strstr(code, "import ") == code || strstr(code, "export ") == code) {
        eval_flags = JS_EVAL_TYPE_MODULE;
    }

    // Execute the JavaScript code with appropriate flags
    JSValue result = JS_Eval(ctx, code, strlen(code), "<input>", eval_flags);
    
    // If it's a module, we need to handle the module promise
    if (eval_flags == JS_EVAL_TYPE_MODULE && !JS_IsException(result)) {
        JSValue promise = JS_GetPropertyStr(ctx, result, "promise");
        // Wait for module evaluation to complete
        // Note: In a real implementation you'd want to handle this asynchronously
        JS_FreeValue(ctx, result);
        result = promise;
    }
    
    // Check for errors
    if (JS_IsException(result)) {
        JSValue error = JS_GetException(ctx);
        const char *error_str = JS_ToCString(ctx, error);
        ao_log(error_str);
        JS_FreeCString(ctx, error_str);
        JS_FreeValue(ctx, error);
    }
    
    // Clean up
    JS_FreeValue(ctx, result);
    cJSON_Delete(msgJson);
    JS_FreeContext(ctx);
    JS_FreeRuntime(JS_GetRuntime(ctx));
    
    // Return the final result from the ao environment
    return ao_result("{}");
}