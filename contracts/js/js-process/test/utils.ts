import AoLoader from '@permaweb/ao-loader';

import {
  AO_LOADER_HANDLER_ENV,
  AO_LOADER_OPTIONS,
  DEFAULT_HANDLE_OPTIONS,
  JS_WASM_MODULE,
} from './constants.js';

export async function createJsProcessLoader(wasmModule = JS_WASM_MODULE) {
  const handle = await AoLoader(wasmModule, AO_LOADER_OPTIONS);
  // just to get the mem buffer originally
  const evalRes = await handle(
    null,
    {
      ...DEFAULT_HANDLE_OPTIONS,

      Tags: [{ name: 'Action', value: 'Eval' }],
      Data: "print('foo')",
    },

    AO_LOADER_HANDLER_ENV,
  );

  return {
    handle,
    memory: evalRes.Memory,
  };
}

export function createHandleWrapper(
  ogHandle,
  startMem,
  defaultHandleOptions = DEFAULT_HANDLE_OPTIONS,
  aoLoaderHandlerEnv = AO_LOADER_HANDLER_ENV,
) {
  return async function (options = {}, mem = startMem) {
    return ogHandle(
      mem,
      {
        ...defaultHandleOptions,
        ...options,
      },
      aoLoaderHandlerEnv,
    );
  };
}
