/**
 * Ensure ui/public/header-logo.png exists so the in-app header shows the logo.
 * If missing, creates a simple "LAYMO" placeholder. Replace with your own image to customize.
 */
import { writeFile, access } from 'fs/promises';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const publicLogo = join(__dirname, '..', 'public', 'header-logo.png');

try {
  await access(publicLogo);
  // File exists, nothing to do
} catch {
  try {
    const sharp = (await import('sharp')).default;
    const svg = `
      <svg width="200" height="56" xmlns="http://www.w3.org/2000/svg">
        <text x="0" y="42" font-family="system-ui, sans-serif" font-size="32" font-weight="700" fill="white" letter-spacing="0.05em">LAYMO</text>
      </svg>
    `;
    const buf = await sharp(Buffer.from(svg))
      .png()
      .toBuffer();
    await writeFile(publicLogo, buf);
    console.log('[Laymo] Created placeholder header-logo.png in ui/public. Replace with your own image to customize.');
  } catch (e) {
    if (e.code === 'ERR_MODULE_NOT_FOUND' && e.message.includes('sharp')) {
      console.warn('[Laymo] Add ui/public/header-logo.png for the in-app header logo, or install sharp and rebuild.');
    } else {
      console.warn('[Laymo] Could not create header logo:', e.message);
    }
  }
}
