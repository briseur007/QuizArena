// Lance vitest depuis le chemin RÉEL du dossier api/.
//
// Sous Windows, un terminal peut ouvrir le dossier en « c:\… » alors que le disque
// est « C:\… ». Node identifie les modules par leur chemin exact : vitest se
// retrouve chargé deux fois et échoue avec « Vitest failed to find the runner ».
// Sous Linux/macOS (CI comprise), ce script ne change rien.
import { spawnSync } from 'node:child_process';
import { realpathSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const apiDir = realpathSync.native(join(dirname(fileURLToPath(import.meta.url)), '..'));
const cli = join(apiDir, 'node_modules', 'vitest', 'vitest.mjs');

const { status } = spawnSync(process.execPath, [cli, ...process.argv.slice(2)], { cwd: apiDir, stdio: 'inherit' });
process.exit(status ?? 1);
