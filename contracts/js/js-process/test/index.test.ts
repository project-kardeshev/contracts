import assert from 'node:assert';
import { describe, it } from 'node:test';

import { createHandleWrapper, createJsProcessLoader } from './utils.js';

describe('js-process', async () => {
  const { handle, memory } = await createJsProcessLoader();

  const sendMessage = createHandleWrapper(handle, memory);

  it('should be a function', async () => {
    const res = await sendMessage({
      Data: 'print("Hello, world!")',
    });
    console.log(res);
    assert.ok(res);
  });
});
