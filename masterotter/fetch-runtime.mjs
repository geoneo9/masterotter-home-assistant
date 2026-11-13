import { readFileSync, createWriteStream, mkdirSync, rmSync } from 'node:fs';
import { createHash } from 'node:crypto';
import https from 'node:https';
import { Transform } from 'node:stream';
import { pipeline } from 'node:stream/promises';
import { execFileSync } from 'node:child_process';

const release = JSON.parse(readFileSync('/build/runtime.json', 'utf8'));
if (!/^\d+\.\d+\.\d+$/.test(release.version) ||
    release.url !== `https://masterotter.com/downloads/apps/homeassistant/masterotter-runtime-${release.version}.tar.gz` ||
    !/^[a-f0-9]{64}$/.test(release.sha256) || !Number.isSafeInteger(release.sizeBytes) ||
    release.sizeBytes < 1 || release.sizeBytes > 100 * 1024 * 1024) throw Error('Invalid runtime manifest');
const archive = '/tmp/masterotter-runtime.tar.gz';
const hash = createHash('sha256');
let bytes = 0;
function download(url, redirects = 0) {
  return new Promise((resolve, reject) => {
    const req = https.get(url, { timeout: 60000 }, response => {
      if ([301, 302, 303, 307, 308].includes(response.statusCode)) {
        response.resume();
        const next = new URL(response.headers.location ?? '', url);
        if (redirects >= 3 || next.protocol !== 'https:' || next.host !== 'masterotter.com' || next.username || next.password) return reject(Error('Untrusted runtime redirect'));
        resolve(download(next, redirects + 1));
      } else if (response.statusCode !== 200) {
        response.resume(); reject(Error(`Runtime download HTTP ${response.statusCode}`));
      } else resolve(response);
    });
    req.on('timeout', () => req.destroy(Error('Runtime download timed out')));
    req.on('error', reject);
  });
}
try {
  await pipeline(await download(release.url), new Transform({ transform(chunk, encoding, cb) {
    bytes += chunk.length;
    if (bytes > release.sizeBytes) return cb(Error('Runtime exceeds declared size'));
    hash.update(chunk); cb(null, chunk);
  }}), createWriteStream(archive, { flags: 'wx', mode: 0o600 }));
  if (bytes !== release.sizeBytes || hash.digest('hex') !== release.sha256) throw Error('Runtime checksum or size mismatch');
  mkdirSync('/opt/masterotter', { recursive: true });
  execFileSync('tar', ['-xzf', archive, '-C', '/opt/masterotter', '--strip-components=1']);
  const pkg = JSON.parse(readFileSync('/opt/masterotter/package.json', 'utf8'));
  if (pkg.version !== release.version) throw Error('Runtime version mismatch');
} finally { rmSync(archive, { force: true }); }
