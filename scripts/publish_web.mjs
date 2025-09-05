import { execSync } from 'child_process';
import { existsSync, mkdirSync, readdirSync, copyFileSync, writeFileSync } from 'fs';
import path from 'path';

// Environment variables:
//   SQLCL_BIN   - path to Oracle SQLcl `sql` executable
//   LIQUI_USER  - database user for exporting KPIs
//   LIQUI_PASS  - password for the user
//   LIQUI_URL   - connection string (host:port/service)
//   EXPORT_DIR  - directory containing exported CSV files

const sqlcl = process.env.SQLCL_BIN;
const dbUser = process.env.LIQUI_USER;
const dbPass = process.env.LIQUI_PASS;
const dbUrl = process.env.LIQUI_URL;

try {
  if (!sqlcl) {
    console.warn('SQLCL_BIN no definido; se omite exportación de BD');
  } else if (dbUser && dbPass && dbUrl) {
    execSync(`${sqlcl} ${dbUser}/${dbPass}@${dbUrl} @scripts/publish_kpis.sql`, { stdio: 'inherit' });
  } else {
    console.warn('LIQUI_URL/LIQUI_USER/LIQUI_PASS incompletos; se omite SQLcl');
  }
} catch (e) {
  console.error('Error ejecutando SQLcl', e.message);
}

const exportDir = process.env.EXPORT_DIR;
const destDir = path.resolve('web-app/public/data');
mkdirSync(destDir, { recursive: true });

if (!exportDir) {
  console.warn('EXPORT_DIR no definido; no se copiarán CSV');
} else if (existsSync(exportDir)) {
  const files = readdirSync(exportDir).filter(f => f.endsWith('.csv'));
  files.forEach(f => copyFileSync(path.join(exportDir, f), path.join(destDir, f)));
  const latest = { generated: new Date().toISOString(), files };
  writeFileSync(path.join(destDir, 'latest.json'), JSON.stringify(latest, null, 2));
  console.log('CSV copiados');
} else {
  console.log('Directorio de export no existe:', exportDir);
}
