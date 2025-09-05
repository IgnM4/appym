async function loadI18n() {
  const res = await fetch('i18n.json');
  const data = await res.json();
  const lang = navigator.language.startsWith('es') ? 'es' : 'en';
  document.documentElement.lang = lang;
  document.querySelectorAll('[data-i18n]').forEach((el) => {
    const key = el.getAttribute('data-i18n');
    const txt = data[lang][key];
    if (txt) el.textContent = txt;
  });
}

document.addEventListener('DOMContentLoaded', loadI18n);
