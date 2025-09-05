async function loadCsv(url){
  const res = await fetch(url);
  const txt = await res.text();
  return new Promise(resolve => Papa.parse(txt, { header:true, skipEmptyLines:true, complete: r => resolve(r.data) }));
}

function renderTable(elId, rows){
  const el = document.getElementById(elId);
  const thead = el.querySelector('thead'), tbody = el.querySelector('tbody');
  if(!rows.length){ thead.innerHTML=''; tbody.innerHTML='<tr><td>Sin datos</td></tr>'; return; }
  const cols = Object.keys(rows[0]);
  thead.innerHTML = `<tr>${cols.map(c=>`<th>${c}</th>`).join('')}</tr>`;
  tbody.innerHTML = rows.map(r => `<tr>${cols.map(c=>`<td>${r[c]}</td>`).join('')}</tr>`).join('');
}

(async () => {
  const dia = await loadCsv('data/ventas_hoy.csv');            // o el con fecha
  const prod = await loadCsv('data/ventas_prod_ult7d.csv');    // o el con fecha
  renderTable('tblDia', dia);
  renderTable('tblProd', prod);
})();
