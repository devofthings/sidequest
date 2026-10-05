// Render the selected editable Card S into its production Any icon slot.
// Usage: NODE_PATH=<existing node_modules> node docs/logo-concepts/render-icon.cjs
const fs = require('node:fs/promises');
const path = require('node:path');
const sharp = require('sharp');
const directory = __dirname;

async function render() {
  const svg = await fs.readFile(path.join(directory, 'card-s.svg'));
  const destination = path.join(directory, '../../Sidequest/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png');
  await sharp(svg).resize(1024, 1024).removeAlpha().withIccProfile('srgb')
    .png().toFile(destination);
}
render().catch(error => { console.error(error); process.exitCode = 1; });
