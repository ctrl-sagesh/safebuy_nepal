/**
 * SafeBuy Nepal — auto-deploy watcher
 * Watches this folder; whenever you edit & save a file, it waits a few seconds
 * (so it batches your edits) then deploys to Vercel automatically.
 * Your installed PWA updates itself the next time it's opened.
 *
 * Run it with: auto-deploy.bat   (or:  node auto-deploy.js )
 * Stop it with: Ctrl + C
 */
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

const DIR = __dirname;
const IGNORE = ['.vercel', 'node_modules', '.git'];
const DEBOUNCE_MS = 6000;

let timer = null;
let deploying = false;
let pending = false;

function deploy() {
  if (deploying) { pending = true; return; }
  deploying = true;
  console.log('\n[deploy] Publishing to Vercel...');
  const cmd = process.platform === 'win32' ? 'vercel.cmd' : 'vercel';
  const p = spawn(cmd, ['--prod', '--yes'], { cwd: DIR, stdio: 'inherit', shell: true });
  p.on('close', () => {
    deploying = false;
    console.log('[deploy] Done — your app will update on next open.\n');
    if (pending) { pending = false; schedule(); }
  });
}

function schedule() {
  clearTimeout(timer);
  timer = setTimeout(deploy, DEBOUNCE_MS);
}

try {
  fs.watch(DIR, { recursive: true }, (evt, file) => {
    if (!file) return;
    const parts = file.split(path.sep);
    if (IGNORE.some((i) => parts.includes(i))) return;
    if (file.endsWith('~') || path.basename(file).startsWith('.')) return;
    console.log('[change] ' + file + '  →  deploying in ' + (DEBOUNCE_MS / 1000) + 's...');
    schedule();
  });
  console.log('👀 Watching: ' + DIR);
  console.log('Edit & save your files — it auto-deploys ' + (DEBOUNCE_MS / 1000) + 's after you stop typing.');
  console.log('Press Ctrl + C to stop.\n');
} catch (e) {
  console.error('Could not start watcher:', e.message);
  process.exit(1);
}
