#!/usr/bin/env node
import sharp from 'sharp';
import { readFileSync, existsSync, mkdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = join(__dirname, '..');
const iconsDir = join(projectRoot, 'public', 'icons');

// Ensure icons directory exists
if (!existsSync(iconsDir)) {
  mkdirSync(iconsDir, { recursive: true });
}

// Read the SVG file
const svgBuffer = readFileSync(join(iconsDir, 'icon.svg'));

// Icon sizes to generate
const sizes = [
  { size: 192, name: 'icon-192x192.png' },
  { size: 512, name: 'icon-512x512.png' },
  { size: 180, name: 'apple-touch-icon.png' },
  { size: 167, name: 'icon-167x167.png' }, // iPad Pro
  { size: 152, name: 'icon-152x152.png' }, // iPad
  { size: 120, name: 'icon-120x120.png' }, // iPhone
];

// Generate icons
async function generateIcons() {
  for (const { size, name } of sizes) {
    try {
      await sharp(svgBuffer)
        .resize(size, size)
        .png()
        .toFile(join(iconsDir, name));
      console.log(`✓ Generated ${name}`);
    } catch (error) {
      console.error(`✗ Failed to generate ${name}:`, error.message);
    }
  }
}

generateIcons().catch(console.error);