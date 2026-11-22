"""Mini e-commerce: catálogo y pedidos en MySQL (RDS), carrito en Redis (ElastiCache)."""
import json, os, time, uuid
import pymysql, redis
from flask import Flask, redirect, render_template_string, request, make_response

app = Flask(__name__)
R = redis.Redis(host=os.environ["REDIS_HOST"], port=6379, decode_responses=True)


def db():
    return pymysql.connect(host=os.environ["DB_HOST"], user=os.environ["DB_USER"],
                           password=os.environ["DB_PASSWORD"], database=os.environ["DB_NAME"],
                           cursorclass=pymysql.cursors.DictCursor, autocommit=True)


def init_db():
    for _ in range(30):  # la base puede tardar en aceptar conexiones
        try:
            c = db()
            break
        except Exception:
            time.sleep(5)
    else:
        raise RuntimeError("No hay conexión a MySQL")
    with c.cursor() as cur:
        # Candado: con 2 procesos de gunicorn, solo uno inicializa a la vez
        cur.execute("SELECT GET_LOCK('init_tienda', 60)")
        cur.execute("CREATE TABLE IF NOT EXISTS productos (id INT AUTO_INCREMENT PRIMARY KEY,"
                    " nombre VARCHAR(80), precio INT)")
        cur.execute("CREATE TABLE IF NOT EXISTS pedidos (id INT AUTO_INCREMENT PRIMARY KEY,"
                    " total INT, detalle TEXT, creado TIMESTAMP DEFAULT CURRENT_TIMESTAMP)")
        # Limpia duplicados de ejecuciones anteriores y evita que vuelvan
        cur.execute("DELETE a FROM productos a JOIN productos b"
                    " ON a.nombre = b.nombre AND a.id > b.id")
        try:
            cur.execute("ALTER TABLE productos ADD UNIQUE KEY uq_nombre (nombre)")
        except Exception:
            pass  # ya existe
        cur.executemany("INSERT IGNORE INTO productos (nombre, precio) VALUES (%s, %s)",
                        [("Camiseta ITM", 35000), ("Taza Cloud", 22000),
                         ("Termo Terraform", 48000), ("Gorra AWS", 30000)])
        cur.execute("SELECT RELEASE_LOCK('init_tienda')")
    c.close()


def productos():
    """Catálogo: primero Redis (caché 30 s); si no está, MySQL."""
    data = R.get("catalogo")
    if data:
        return json.loads(data), "Redis (ElastiCache)"
    with db().cursor() as cur:
        cur.execute("SELECT * FROM productos")
        rows = cur.fetchall()
    R.setex("catalogo", 30, json.dumps(rows))
    return rows, "MySQL (RDS)"


def sid():
    return request.cookies.get("sid") or uuid.uuid4().hex


def finish(resp, s):
    resp.set_cookie("sid", s)
    return resp


ICONOS = {"Camiseta ITM": "👕", "Taza Cloud": "☕", "Termo Terraform": "🧴", "Gorra AWS": "🧢"}

PAGE = """<!doctype html><html lang=es><head><meta charset=utf-8>
<meta name=viewport content="width=device-width,initial-scale=1"><title>Tienda ITM</title>
<style>
*{box-sizing:border-box}
body{margin:0;font-family:system-ui,Segoe UI,Roboto,sans-serif;background:#f4f6f9;color:#1f2937}
header{background:#232f3e;color:#fff;padding:1rem 0}
.w{max-width:860px;margin:0 auto;padding:0 1rem}
header .w{display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:.5rem}
header h1{margin:0;font-size:1.4rem}
nav a{color:#fff;text-decoration:none;margin-left:1.2rem;font-weight:500;opacity:.85}
nav a:hover{opacity:1;text-decoration:underline}
main{padding:1.5rem 0 3rem}
.src{display:inline-block;background:#e0ecff;color:#1d4ed8;border-radius:999px;padding:.25rem .8rem;font-size:.85rem;margin-bottom:1rem}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(190px,1fr));gap:1rem}
.card{background:#fff;border-radius:12px;padding:1.2rem;text-align:center;box-shadow:0 1px 4px rgba(0,0,0,.08)}
.card .ic{font-size:3rem}
.card h3{margin:.5rem 0 .2rem;font-size:1.05rem}
.price{color:#059669;font-weight:700;margin-bottom:.8rem}
.btn{display:inline-block;background:#ff9900;color:#111;border:0;border-radius:8px;padding:.5rem 1rem;font-weight:600;text-decoration:none;cursor:pointer;font-size:.95rem}
.btn:hover{background:#e68a00}
table{width:100%;border-collapse:collapse;background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 1px 4px rgba(0,0,0,.08)}
th,td{padding:.7rem 1rem;text-align:left;border-bottom:1px solid #eef0f3}
th{background:#f9fafb;font-size:.85rem;color:#6b7280}
.total{text-align:right;font-size:1.2rem;font-weight:700;margin:1rem 0}
.empty{background:#fff;padding:2rem;border-radius:12px;text-align:center;color:#6b7280}
</style></head><body>
<header><div class=w><h1>🛒 Tienda ITM</h1>
<nav><a href=/>Catálogo</a><a href=/cart>Carrito</a><a href=/orders>Pedidos</a></nav></div></header>
<main><div class=w>{{ body|safe }}</div></main></body></html>"""


@app.route("/")
def index():
    rows, src = productos()
    body = f"<span class=src>Catálogo servido desde: <b>{src}</b></span><div class=grid>"
    for p in rows:
        body += (f"<div class=card><div class=ic>{ICONOS.get(p['nombre'], '📦')}</div>"
                 f"<h3>{p['nombre']}</h3><div class=price>${p['precio']:,}</div>"
                 f"<a class=btn href=/add/{p['id']}>Agregar al carrito</a></div>")
    return render_template_string(PAGE, body=body + "</div>")


@app.route("/add/<int:pid>")
def add(pid):
    s = sid()
    R.hincrby(f"cart:{s}", str(pid), 1)
    R.expire(f"cart:{s}", 3600)
    return finish(make_response(redirect("/cart")), s)


@app.route("/cart")
def cart():
    s = sid()
    items = R.hgetall(f"cart:{s}")
    precios = {str(p["id"]): p for p in productos()[0]}
    body = "<span class=src>Carrito guardado en: <b>Redis (ElastiCache)</b></span>"
    if not items:
        body += "<div class=empty>Tu carrito está vacío.</div>"
    else:
        total = 0
        body += "<table><tr><th>Producto</th><th>Cantidad</th><th>Subtotal</th></tr>"
        for pid, qty in items.items():
            p = precios[pid]
            sub = p["precio"] * int(qty)
            total += sub
            body += f"<tr><td>{p['nombre']}</td><td>{qty}</td><td>${sub:,}</td></tr>"
        body += (f"</table><div class=total>Total: ${total:,}</div>"
                 "<form method=post action=/checkout style='text-align:right'>"
                 "<button class=btn>Comprar</button></form>")
    return finish(make_response(render_template_string(PAGE, body=body)), s)


@app.route("/checkout", methods=["POST"])
def checkout():
    s = sid()
    items = R.hgetall(f"cart:{s}")
    if items:
        precios = {str(p["id"]): p for p in productos()[0]}
        total = sum(precios[k]["precio"] * int(v) for k, v in items.items())
        detalle = ", ".join(f"{precios[k]['nombre']} x{v}" for k, v in items.items())
        with db().cursor() as cur:
            cur.execute("INSERT INTO pedidos (total, detalle) VALUES (%s, %s)", (total, detalle))
        R.delete(f"cart:{s}")
    return redirect("/orders")


@app.route("/orders")
def orders():
    with db().cursor() as cur:
        cur.execute("SELECT * FROM pedidos ORDER BY id DESC LIMIT 20")
        rows = cur.fetchall()
    body = "<span class=src>Pedidos guardados en: <b>MySQL (RDS)</b></span>"
    if not rows:
        body += "<div class=empty>Aún no hay pedidos.</div>"
    else:
        body += "<table><tr><th>#</th><th>Detalle</th><th>Total</th><th>Fecha</th></tr>"
        for o in rows:
            body += (f"<tr><td>{o['id']}</td><td>{o['detalle']}</td>"
                     f"<td>${o['total']:,}</td><td>{o['creado']}</td></tr>")
        body += "</table>"
    return render_template_string(PAGE, body=body)


@app.route("/health")
def health():
    R.ping()
    with db().cursor() as cur:
        cur.execute("SELECT 1")
    return "ok"


init_db()
