#!/usr/bin/env node
// Patches workspace package.json exports to use publishConfig.exports (dist/ paths).
// Run this after TypeScript compilation in the Docker build stage so that the
// production Node.js process resolves workspace packages to compiled dist/ files
// rather than raw TypeScript src/ files.

import { readFileSync, writeFileSync, readdirSync, statSync, existsSync } from "fs";
import { join } from "path";

const appRoot = process.argv[2] ?? process.cwd();

if (!existsSync(appRoot)) {
  console.error(`error: directory not found: ${appRoot}`);
  process.exit(1);
}

// Fixed workspace packages plus dynamically discovered adapter packages.
const staticDirs = ["packages/shared", "packages/db", "packages/adapter-utils"];

const adaptersDir = join(appRoot, "packages/adapters");
const adapterDirs = existsSync(adaptersDir)
  ? readdirSync(adaptersDir)
      .filter((name) => statSync(join(adaptersDir, name)).isDirectory())
      .map((name) => `packages/adapters/${name}`)
  : [];

const packageDirs = [...staticDirs, ...adapterDirs];

for (const dir of packageDirs) {
  const pkgPath = join(appRoot, dir, "package.json");
  let pkg;
  try {
    pkg = JSON.parse(readFileSync(pkgPath, "utf8"));
  } catch (err) {
    console.error(`error: failed to read/parse ${dir}/package.json: ${err.message}`);
    process.exit(1);
  }
  if (pkg.publishConfig?.exports) {
    pkg.exports = pkg.publishConfig.exports;
    writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + "\n");
    console.log(`patched exports in ${dir}/package.json`);
  } else {
    console.log(`no publishConfig.exports in ${dir}/package.json, skipping`);
  }
}
