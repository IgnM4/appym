import { parseCsv } from './csv.js';

const statusEl = document.getElementById('dashStatus');

async function init() {
  statusEl.textContent = 'Cargando KPIs...';
  try {
    const res = await fetch('data/latest.json');
    const info = await res.json();
    if (!info.files || info.files.length === 0) {
      statusEl.textContent = 'No hay datos para mostrar';
      return;
    }
    for (const f of info.files) {
      const csv = await fetch(`data/${f}`).then((r) => r.text());
      console.log(parseCsv(csv));
    }
    statusEl.textContent = '';
  } catch (e) {
    statusEl.textContent = 'Error al cargar KPIs';
    statusEl.classList.add('error');
    console.error('No se pudieron cargar KPIs', e);
  }
}

init();
