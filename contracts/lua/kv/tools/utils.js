import AoLoader from '@permaweb/ao-loader';

import {
  AOS_WASM,
  AO_LOADER_HANDLER_ENV,
  AO_LOADER_OPTIONS,
  BUNDLED_KV_REGISTRY_AOS_LUA,
  BUNDLED_KV_STORE_AOS_LUA,
  DEFAULT_HANDLE_OPTIONS,
  STUB_ADDRESS,
} from './constants.js';

/**
 * Loads the aos wasm binary and returns the handle function with program memory
 * @returns {Promise<{handle: Function, memory: WebAssembly.Memory}>}
 */
export async function createAosLoader(lua) {
  const handle = await AoLoader(AOS_WASM, AO_LOADER_OPTIONS);

  const evalRes = await handle(
    null,
    {
      ...DEFAULT_HANDLE_OPTIONS,
      Tags: [{ name: 'Action', value: 'Eval' }],
      Data: lua,
    },
    AO_LOADER_HANDLER_ENV,
  );

  return { handle, memory: evalRes.Memory };
}

export async function createKVRegistryAosLoader() {
  return createAosLoader(BUNDLED_KV_REGISTRY_AOS_LUA);
}

export async function createKVStoreAosLoader() {
  return createAosLoader(BUNDLED_KV_STORE_AOS_LUA);
}

export async function getHandlers(sendMessage, memory) {
  const res = await sendMessage(
    {
      Tags: [{ name: 'Action', value: 'Eval' }],
      Data: `ao.send({Data = require("json").encode(require(".utils").getHandlerNames(Handlers)), Target = "${STUB_ADDRESS}"})`,
    },
    memory,
  );

  return JSON.parse(res.Messages[0].Data);
}
