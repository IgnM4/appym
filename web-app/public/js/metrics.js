window.addEventListener('load', () => {
  const ms = performance.now();
  console.log(`Tiempo de carga: ${ms.toFixed(0)} ms`);
  const el = document.getElementById('metrics');
  if (el) {
    el.textContent = `Tiempo de carga: ${Math.round(ms)} ms`;
  }
});
