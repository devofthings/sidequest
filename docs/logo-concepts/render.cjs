// Render original SVG review proposals with an existing Sharp installation.
// Usage: NODE_PATH=<existing node_modules> node docs/logo-concepts/render.cjs
const fs = require('node:fs/promises');
const path = require('node:path');
const sharp = require('sharp');
const directory = __dirname;
const names = ['card-s', 'sidepath', 'mixed-deck'];
const labels = ['A / Card S', 'B / Sidepath', 'C / Mixed Deck'];

async function render() {
  const layers = [];
  const sizes = [256, 64, 40, 24];
  for (const [index, name] of names.entries()) {
    const input = await fs.readFile(path.join(directory, `${name}.svg`));
    for (const [row, size] of sizes.entries()) {
      const png = await sharp(input).resize(size, size).png().toBuffer();
      if (row === 0) await fs.writeFile(path.join(directory, `${name}-preview.png`), png);
      layers.push({ input: png, left: 70 + index * 360, top: [70, 380, 500, 600][row] });
    }
  }
  const text = `<svg width="1120" height="710" xmlns="http://www.w3.org/2000/svg"><g font-family="sans-serif" fill="#191524"><text x="70" y="32" font-size="20">Sidequest / original proposals / no final selection</text>${labels.map((label, i) => `<text x="${70 + i * 360}" y="355" font-size="21">${label}</text>`).join('')}<g font-size="14">${[256, 64, 40, 24].map((size, i) => `<text x="20" y="${[90, 400, 520, 620][i]}">${size}</text>`).join('')}<text x="70" y="690">Sizes shown in pixels. View at 100% for the 64, 40, and 24 px samples.</text></g></g></svg>`;
  layers.push({ input: Buffer.from(text), left: 0, top: 0 });
  await sharp({ create: { width: 1120, height: 710, channels: 3, background: '#F5F1EA' } })
    .composite(layers).png().toFile(path.join(directory, 'size-proof.png'));
}
render().catch(error => { console.error(error); process.exitCode = 1; });
