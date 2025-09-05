const fmt = new Intl.NumberFormat('es-CL', {
  style: 'currency',
  currency: 'CLP',
});

let products = [];
let cart = JSON.parse(localStorage.getItem('cart') || '[]');

const productsEl = document.getElementById('lista-productos');
const cartEl = document.getElementById('items-carrito');
const totalEl = document.getElementById('total');
const searchInput = document.getElementById('buscar');
const processBtn = document.getElementById('procesar');
const messageEl = document.getElementById('mensaje');

function showMessage(msg = '', type = '') {
  if (!messageEl) return;
  messageEl.textContent = msg;
  messageEl.className = type;
}

function showError(msg) {
  showMessage(msg, 'error');
  setTimeout(() => showMessage(), 3000);
}

function saveCart() {
  localStorage.setItem('cart', JSON.stringify(cart));
}

function renderCart() {
  cartEl.innerHTML = '';
  if (!cart.length) {
    cartEl.innerHTML = '<li>Carrito vacío</li>';
    totalEl.textContent = '';
    return;
  }
  let total = 0;
  for (const item of cart) {
    total += item.precio * item.qty;
    const li = document.createElement('li');
    li.textContent = `${item.nombre} x${item.qty} (${fmt.format(item.precio * item.qty)})`;
    cartEl.appendChild(li);
  }
  totalEl.textContent = `Total: ${fmt.format(total)}`;
  saveCart();
}

function addToCart(product) {
  const existing = cart.find((c) => c.sku === product.sku);
  const qty = existing ? existing.qty + 1 : 1;
  if (qty > product.stock) {
    showError(`No hay stock suficiente de ${product.nombre}`);
    return;
  }
  if (existing) {
    existing.qty++;
  } else {
    cart.push({ ...product, qty: 1 });
  }
  renderCart();
}

function renderProducts(list) {
  productsEl.innerHTML = '';
  if (!list.length) {
    productsEl.textContent = 'Sin productos';
    return;
  }
  for (const p of list) {
    const div = document.createElement('div');
    div.className = 'producto';
    const btn = document.createElement('button');
    btn.textContent = 'Agregar';
    btn.addEventListener('click', () => addToCart(p));
    div.innerHTML = `<strong>${p.nombre}</strong> - ${fmt.format(p.precio)} `;
    div.appendChild(btn);
    productsEl.appendChild(div);
  }
}

function showProductSkeleton(count = 3) {
  productsEl.innerHTML = '';
  for (let i = 0; i < count; i++) {
    const sk = document.createElement('div');
    sk.className = 'producto skeleton';
    productsEl.appendChild(sk);
  }
}

async function loadProducts() {
  showProductSkeleton();
  try {
    const res = await fetch('data/products.json');
    products = await res.json();
    renderProducts(products);
    renderCart();
  } catch (e) {
    productsEl.textContent = 'Error al cargar productos';
  }
}

searchInput?.addEventListener('input', (e) => {
  const term = e.target.value.toLowerCase();
  const filtered = products.filter(
    (p) =>
      p.nombre.toLowerCase().includes(term) ||
      p.sku.toLowerCase().includes(term),
  );
  renderProducts(filtered);
});

processBtn?.addEventListener('click', () => {
  if (!cart.length) {
    showError('El carrito está vacío');
    return;
  }
  cart = [];
  saveCart();
  renderCart();
  showMessage('Venta procesada');
});

loadProducts();
