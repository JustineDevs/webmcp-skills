Object.defineProperty(document, 'modelContext', {
  configurable: true,
  value: {
    async getTools() {
      return [
        {
          name: 'echo',
          title: 'Echo',
          description: 'Returns the supplied message.',
          inputSchema: {
            type: 'object',
            properties: {message: {type: 'string'}},
            required: ['message'],
            additionalProperties: false,
          },
          origin: location.origin,
        },
      ];
    },
    async executeTool(tool, input, {signal} = {}) {
      if (tool.name !== 'echo') throw new Error('unknown fixture tool');
      if (signal?.aborted) throw new DOMException('Aborted', 'AbortError');
      return JSON.stringify({message: String(input.message), verified: true});
    },
  },
});
