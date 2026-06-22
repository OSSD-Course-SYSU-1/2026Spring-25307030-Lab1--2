const http = require('http');
const crypto = require('crypto');

const PORT = Number(process.env.CHAT_RELAY_PORT || 8787);
let latestEnvelope = '';
let latestUpdatedAt = 0;
const clients = new Set();

function acceptKey(key) {
  return crypto
    .createHash('sha1')
    .update(key + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11')
    .digest('base64');
}

function encodeFrame(data, opcode = 0x1) {
  const payload = Buffer.isBuffer(data) ? data : Buffer.from(data);
  const length = payload.length;
  if (length < 126) {
    return Buffer.concat([Buffer.from([0x80 | opcode, length]), payload]);
  }
  if (length < 65536) {
    const header = Buffer.alloc(4);
    header[0] = 0x80 | opcode;
    header[1] = 126;
    header.writeUInt16BE(length, 2);
    return Buffer.concat([header, payload]);
  }
  const header = Buffer.alloc(10);
  header[0] = 0x80 | opcode;
  header[1] = 127;
  header.writeBigUInt64BE(BigInt(length), 2);
  return Buffer.concat([header, payload]);
}

function decodeFrames(buffer) {
  const messages = [];
  let offset = 0;
  while (offset + 2 <= buffer.length) {
    const frameStart = offset;
    const first = buffer[offset++];
    const second = buffer[offset++];
    const opcode = first & 0x0f;
    const masked = (second & 0x80) !== 0;
    let length = second & 0x7f;

    if (length === 126) {
      if (offset + 2 > buffer.length) {
        offset = frameStart;
        break;
      }
      length = buffer.readUInt16BE(offset);
      offset += 2;
    } else if (length === 127) {
      if (offset + 8 > buffer.length) {
        offset = frameStart;
        break;
      }
      length = Number(buffer.readBigUInt64BE(offset));
      offset += 8;
    }

    let mask;
    if (masked) {
      if (offset + 4 > buffer.length) {
        offset = frameStart;
        break;
      }
      mask = buffer.subarray(offset, offset + 4);
      offset += 4;
    }

    if (offset + length > buffer.length) {
      offset = frameStart;
      break;
    }

    const payload = Buffer.from(buffer.subarray(offset, offset + length));
    offset += length;

    if (masked && mask) {
      for (let i = 0; i < payload.length; i += 1) {
        payload[i] ^= mask[i % 4];
      }
    }

    if (opcode === 0x8) {
      messages.push({ type: 'close' });
    } else if (opcode === 0x9) {
      messages.push({ type: 'ping', payload });
    } else if (opcode === 0xA) {
      messages.push({ type: 'pong' });
    } else if (opcode === 0x1) {
      messages.push({ type: 'text', text: payload.toString('utf8') });
    }
  }
  return {
    messages,
    remaining: buffer.subarray(offset)
  };
}

function broadcast(text, except) {
  const frame = encodeFrame(text);
  for (const client of clients) {
    if (client !== except && !client.destroyed) {
      client.write(frame);
    }
  }
}

function handleMessage(text, socket) {
  try {
    const envelope = JSON.parse(text);
    if (typeof envelope.updatedAt !== 'number') {
      return;
    }
    if (envelope.updatedAt <= latestUpdatedAt) {
      if (latestEnvelope) {
        socket.write(encodeFrame(latestEnvelope));
      }
      return;
    }
    latestUpdatedAt = envelope.updatedAt;
    latestEnvelope = text;
    broadcast(text, socket);
    console.log(`[relay] updated ${new Date(latestUpdatedAt).toISOString()} clients=${clients.size}`);
  } catch (err) {
    console.warn('[relay] ignored invalid message', err.message);
  }
}

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'content-type': 'text/plain; charset=utf-8' });
  res.end('chat relay is running\n');
});

server.on('upgrade', (req, socket) => {
  const key = req.headers['sec-websocket-key'];
  if (!key) {
    socket.destroy();
    return;
  }

  socket.write([
    'HTTP/1.1 101 Switching Protocols',
    'Upgrade: websocket',
    'Connection: Upgrade',
    `Sec-WebSocket-Accept: ${acceptKey(key)}`,
    '',
    ''
  ].join('\r\n'));

  clients.add(socket);
  socket.relayBuffer = Buffer.alloc(0);
  console.log(`[relay] client connected clients=${clients.size}`);
  if (latestEnvelope) {
    socket.write(encodeFrame(latestEnvelope));
  }

  socket.on('data', (buffer) => {
    const decoded = decodeFrames(Buffer.concat([socket.relayBuffer, buffer]));
    socket.relayBuffer = decoded.remaining;
    for (const message of decoded.messages) {
      if (message.type === 'close') {
        socket.write(encodeFrame(Buffer.alloc(0), 0x8));
        socket.end();
      } else if (message.type === 'ping') {
        socket.write(encodeFrame(message.payload, 0xA));
      } else if (message.type === 'text') {
        handleMessage(message.text, socket);
      }
    }
  });

  socket.on('close', () => {
    clients.delete(socket);
    console.log(`[relay] client closed clients=${clients.size}`);
  });

  socket.on('error', () => {
    clients.delete(socket);
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`[relay] listening on ws://0.0.0.0:${PORT}/chat-sync`);
});
