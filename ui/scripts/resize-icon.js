/**
 * Resize the phone desktop app icon to 256x256 so it matches other lb-phone app icons.
 * Runs after build. Only affects ui/dist/icon.png (the icon on the phone's app list).
 */
import { readFile, writeFile } from 'fs/promises';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const distIcon = join(__dirname, '..', 'dist', 'icon.png');

try {
  const sharp = (await import('sharp')).default;
  const buf = await readFile(distIcon);
  const resized = await sharp(buf)
    .resize(256, 256, { fit: 'cover' })
    .png()
    .toBuffer();
  await writeFile(distIcon, resized);
  console.log('[Laymo] Phone app icon resized to 256x256 to match other apps.');
} catch (e) {
  if (e.code === 'ERR_MODULE_NOT_FOUND' && e.message.includes('sharp')) {
    console.warn('[Laymo] Install sharp (npm install --save-dev sharp) and rebuild to fix app icon size on phone desktop.');
  } else {
    console.warn('[Laymo] Could not resize app icon:', e.message);
  }
}
