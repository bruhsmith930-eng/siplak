import hashlib, os, sqlite3, zipfile, datetime
from flask import Flask, request, jsonify

app = Flask(__name__)
KUNCI = "SIPELAK-2026-KUNCI-RAHASIA-panjang-minimal-32-karakter"
BASE = os.path.dirname(os.path.abspath(__file__))
DB = os.path.join(BASE, "sipelak.db")
BUKTI_DIR = os.path.join(BASE, "bukti")
BERKAS_DIR = os.path.join(BASE, "berkas")
os.makedirs(BUKTI_DIR, exist_ok=True)
os.makedirs(BERKAS_DIR, exist_ok=True)

def db():
    con = sqlite3.connect(DB)
    con.row_factory = sqlite3.Row
    return con

def init():
    con = db()
    con.execute("""CREATE TABLE IF NOT EXISTS laporan(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nomor_hp TEXT, nomor_rekening TEXT, nama_pelaku TEXT, bank TEXT,
        jenis TEXT, kerugian REAL, kronologi TEXT, bukti_chat TEXT,
        pelapor_hash TEXT, waktu TEXT)""")
    con.execute("""CREATE TABLE IF NOT EXISTS bukti(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        laporan_id INTEGER, hash_sha256 TEXT, nama_file TEXT, waktu TEXT)""")
    con.commit(); con.close()
init()

def kunci_ok():
    return request.headers.get("X-API-Key") == KUNCI

@app.get("/")
def ping():
    return "SIPELAK server hidup ✅"

@app.post("/cek")
def cek():
    if not kunci_ok(): return jsonify({"error": "kunci salah"}), 401
    n = (request.json or {}).get("nomor", "").strip()
    con = db()
    rows = con.execute("SELECT * FROM laporan WHERE nomor_hp=?", (n,)).fetchall()
    con.close()
    s = 0
    if rows:
        s = min(100, len(rows)*30
                + (20 if any(r["nomor_rekening"] for r in rows) else 0)
                + (10 if any((r["kerugian"] or 0) > 0 for r in rows) else 0))
    flags = []
    if rows: flags.append(f"⚠️ {len(rows)} laporan masuk untuk nomor ini.")
    if any(r["nomor_rekening"] for r in rows): flags.append("🏦 Nomor rekening pelaku tercatat.")
    if any((r["kerugian"] or 0) > 0 for r in rows): flags.append("💰 Ada kerugian material dilaporkan.")
    v = "TERINDIKASI PENIPUAN TINGGI" if s >= 60 else ("WASPADA - ADA LAPORAN" if s >= 30 else "BELUM ADA LAPORAN TERCATAT")
    return jsonify({"nomor": n, "verdict": v, "skor": s,
                    "jumlah_laporan": len(rows),
                    "korban_unik": len(set(r["pelapor_hash"] for r in rows)),
                    "total_kerugian": int(sum(r["kerugian"] or 0 for r in rows)),
                    "flags": flags})

@app.post("/lapor")
def lapor():
    if not kunci_ok(): return jsonify({"error": "kunci salah"}), 401
    d = request.json or {}
    ph = hashlib.sha256((d.get("pelapor", "") or "anonim").encode()).hexdigest()[:16]
    con = db()
    cur = con.execute("""INSERT INTO laporan(nomor_hp,nomor_rekening,nama_pelaku,bank,jenis,kerugian,kronologi,bukti_chat,pelapor_hash,waktu)
                         VALUES(?,?,?,?,?,?,?,?,?,?)""",
        (d.get("nomor_hp",""), d.get("nomor_rekening",""), d.get("nama_pelaku",""), d.get("bank",""),
         d.get("jenis",""), d.get("kerugian",0), d.get("kronologi",""), d.get("bukti_chat",""),
         ph, datetime.datetime.now().isoformat()))
    con.commit(); i = cur.lastrowid; con.close()
    return jsonify({"id": i})

@app.post("/bukti_file")
def bukti_file():
    if not kunci_ok(): return jsonify({"error": "kunci salah"}), 401
    f = request.files.get("file")
    if f is None: return jsonify({"error": "tidak ada file"}), 400
    data = f.read()
    h = hashlib.sha256(data).hexdigest()
    with open(os.path.join(BUKTI_DIR, h + ".bin"), "wb") as o: o.write(data)
    con = db()
    con.execute("INSERT INTO bukti(laporan_id,hash_sha256,nama_file,waktu) VALUES(?,?,?,?)",
        (int(request.form.get("laporan_id", "0") or 0), h, f.filename, datetime.datetime.now().isoformat()))
    con.commit(); con.close()
    return jsonify({"hash_sha256": h})

@app.get("/berkas/<nomor>")
def berkas(nomor):
    if not kunci_ok(): return jsonify({"error": "kunci salah"}), 401
    con = db()
    rows = con.execute("SELECT * FROM laporan WHERE nomor_hp=?", (nomor,)).fetchall()
    buk = con.execute("SELECT * FROM bukti").fetchall()
    con.close()
    if not rows: return jsonify({"error": "belum ada laporan untuk nomor ini"}), 404
    surat = ["BERKAS BUKTI SIPELAK", "="*40, f"Nomor terlapor: {nomor}",
             f"Dicetak: {datetime.datetime.now().isoformat()}", ""]
    for r in rows:
        surat.append(f"- Laporan #{r['id']} | jenis: {r['jenis']} | kerugian: Rp{int(r['kerugian'] or 0)}")
        surat.append(f"  kronologi: {r['kronologi']}")
    zname = f"berkas_{nomor}.zip"
    with zipfile.ZipFile(os.path.join(BERKAS_DIR, zname), "w") as z:
        z.writestr("surat_pengantar.txt", "\n".join(surat))
        for r in rows: z.writestr(f"laporan_{r['id']}.txt", str(dict(r)))
    return jsonify({"file_zip": zname,
                    "jumlah_korban": len(set(r["pelapor_hash"] for r in rows)),
                    "total_kerugian": int(sum(r["kerugian"] or 0 for r in rows)),
                    "jumlah_bukti": len(buk), "isi_surat": "\n".join(surat)})

@app.get("/statistik")
def statistik():
    if not kunci_ok(): return jsonify({"error": "kunci salah"}), 401
    con = db()
    total = con.execute("SELECT COUNT(DISTINCT nomor_hp) FROM laporan").fetchone()[0]
    per = con.execute("SELECT jenis, COUNT(*) AS kasus, SUM(kerugian) AS rugi FROM laporan GROUP BY jenis").fetchall()
    con.close()
    return jsonify({"total_blacklist": total,
                    "per_jenis": [{"jenis": p["jenis"], "kasus": p["kasus"], "rugi": int(p["rugi"] or 0)} for p in per]})
