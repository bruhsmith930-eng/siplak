import hashlib, os, sqlite3, zipfile, datetime, json
from flask import Flask, request, jsonify

app = Flask(__name__)
KUNCI = "SIPELAK-2026-KUNCI-RAHASIA-panjang-minimal-32-karakter"
HOME = os.path.expanduser("~")
DB = os.path.join(HOME, "sipelak.db")
DIR_BUKTI = os.path.join(HOME, "bukti"); os.makedirs(DIR_BUKTI, exist_ok=True)
DIR_BERKAS = os.path.join(HOME, "berkas"); os.makedirs(DIR_BERKAS, exist_ok=True)

def db():
    c = sqlite3.connect(DB); c.row_factory = sqlite3.Row
    c.execute("""CREATE TABLE IF NOT EXISTS laporan(
        id INTEGER PRIMARY KEY AUTOINCREMENT, nomor_hp TEXT, nomor_rekening TEXT,
        nama_pelaku TEXT, bank TEXT, jenis TEXT, kerugian REAL DEFAULT 0,
        kronologi TEXT, bukti_chat TEXT, pelapor_hash TEXT, waktu TEXT)""")
    c.execute("""CREATE TABLE IF NOT EXISTS bukti(
        id INTEGER PRIMARY KEY AUTOINCREMENT, laporan_id INTEGER,
        hash_sha256 TEXT, nama_file TEXT, waktu TEXT)""")
    return c

def kunci_ok():
    return request.headers.get("X-API-Key", "") == KUNCI

@app.errorhandler(404)
def e404(e): return jsonify(error="Endpoint tidak ditemukan (404)."), 404

@app.errorhandler(Exception)
def eany(e): return jsonify(error="Server error: %s" % e), 500

@app.route("/")
def root(): return "SIPELAK server hidup ✅"

@app.route("/cek", methods=["POST"])
def cek():
    if not kunci_ok(): return jsonify(error="Kunci API ditolak (401)."), 401
    nomor = (request.get_json(silent=True) or {}).get("nomor", "").strip()
    c = db()
    rows = c.execute("SELECT * FROM laporan WHERE nomor_hp=?", (nomor,)).fetchall()
    n = len(rows)
    if n == 0:
        return jsonify(nomor=nomor, verdict="BELUM ADA LAPORAN TERCATAT", skor=0,
                       jumlah_laporan=0, korban_unik=0, total_kerugian=0, flags=[])
    korban = len({r["pelapor_hash"] for r in rows})
    rugi = sum(r["kerugian"] or 0 for r in rows)
    skor = min(100, n * 30 + (20 if rugi > 0 else 0) + (10 if korban >= 2 else 0))
    verdict = "BAHAYA - TERINDIKASI PENIPUAN" if skor >= 60 else "WASPADA - ADA LAPORAN"
    flags = ["📌 Nomor dilaporkan %d kali" % n, "👥 %d pelapor berbeda" % korban,
             "💰 Total kerugian Rp %s" % format(int(rugi), ","),
             "🕒 Laporan terakhir: %s" % rows[-1]["waktu"]]
    teks = ((rows[-1]["bukti_chat"] or "") + (rows[-1]["kronologi"] or "")).lower()
    for kw, ps in [("transfer", "💬 Chat menyebut 'transfer'"), ("otp", "💬 Chat meminta OTP/kode"),
                   ("rekening", "💬 Menyebut nomor rekening"), ("hadiah", "💬 Modus hadiah/undian")]:
        if kw in teks: flags.append(ps)
    return jsonify(nomor=nomor, verdict=verdict, skor=skor, jumlah_laporan=n,
                   korban_unik=korban, total_kerugian=int(rugi), flags=flags)

@app.route("/lapor", methods=["POST"])
def lapor():
    if not kunci_ok(): return jsonify(error="Kunci API ditolak (401)."), 401
    d = request.get_json(silent=True) or {}
    ph = hashlib.sha256(((d.get("pelapor") or "") + "|" + (d.get("nomor_hp") or "")).encode()).hexdigest()[:16]
    c = db()
    cur = c.execute("""INSERT INTO laporan(nomor_hp,nomor_rekening,nama_pelaku,bank,jenis,
        kerugian,kronologi,bukti_chat,pelapor_hash,waktu) VALUES(?,?,?,?,?,?,?,?,?,?)""",
        (d.get("nomor_hp", ""), d.get("nomor_rekening", ""), d.get("nama_pelaku", ""),
         d.get("bank", ""), d.get("jenis", ""), float(d.get("kerugian") or 0),
         d.get("kronologi", ""), d.get("bukti_chat", ""), ph,
         datetime.datetime.now().strftime("%Y-%m-%d %H:%M")))
    c.commit()
    return jsonify(ok=True, id=cur.lastrowid)

@app.route("/bukti_file", methods=["POST"])
def bukti_file():
    if not kunci_ok(): return jsonify(error="Kunci API ditolak (401)."), 401
    f = request.files.get("file")
    if f is None: return jsonify(error="File tidak ada."), 400
    data = f.read(); h = hashlib.sha256(data).hexdigest()
    nama = h[:12] + ".bin"
    open(os.path.join(DIR_BUKTI, nama), "wb").write(data)
    c = db()
    c.execute("INSERT INTO bukti(laporan_id,hash_sha256,nama_file,waktu) VALUES(?,?,?,?)",
              (int(request.form.get("laporan_id") or 0), h, nama,
               datetime.datetime.now().strftime("%Y-%m-%d %H:%M")))
    c.commit()
    return jsonify(ok=True, hash_sha256=h)

@app.route("/berkas/<nomor>")
def berkas(nomor):
    if not kunci_ok(): return jsonify(error="Kunci API ditolak (401)."), 401
    c = db()
    rows = c.execute("SELECT * FROM laporan WHERE nomor_hp=?", (nomor,)).fetchall()
    if not rows: return jsonify(error="Belum ada laporan untuk nomor ini."), 404
    ids = ",".join(str(r["id"]) for r in rows)
    bukti = c.execute("SELECT * FROM bukti WHERE laporan_id IN (%s)" % ids).fetchall()
    rugi = sum(r["kerugian"] or 0 for r in rows)
    surat = ("BERKAS BUKTI SIPELAK\nNomor terlapor: %s\nJumlah laporan: %d\nTotal kerugian: Rp %s\nJumlah bukti tersegel: %d\nDicetak: %s\n\nRINGKASAN KRONOLOGI:\n"
             % (nomor, len(rows), format(int(rugi), ","), len(bukti),
                datetime.datetime.now().strftime("%Y-%m-%d %H:%M")))
    for r in rows: surat += "- [%s] %s\n" % (r["waktu"], r["kronologi"])
    nama_zip = "berkas_%s.zip" % nomor
    with zipfile.ZipFile(os.path.join(DIR_BERKAS, nama_zip), "w") as z:
        z.writestr("surat_pengantar.txt", surat)
        z.writestr("laporan.json", json.dumps([dict(r) for r in rows], ensure_ascii=False, indent=2))
        for b in bukti:
            p = os.path.join(DIR_BUKTI, b["nama_file"])
            if os.path.exists(p): z.write(p, "bukti/" + b["nama_file"])
    return jsonify(file_zip=nama_zip, jumlah_korban=len({r["pelapor_hash"] for r in rows}),
                   total_kerugian=int(rugi), jumlah_bukti=len(bukti), isi_surat=surat)

@app.route("/statistik")
def statistik():
    if not kunci_ok(): return jsonify(error="Kunci API ditolak (401)."), 401
    c = db()
    total = c.execute("SELECT COUNT(DISTINCT nomor_hp) FROM laporan").fetchone()[0]
    pj = c.execute("SELECT jenis, COUNT(*) AS kasus, SUM(kerugian) AS rugi FROM laporan GROUP BY jenis").fetchall()
    return jsonify(total_blacklist=total,
                   per_jenis=[{"jenis": r["jenis"], "kasus": r["kasus"], "rugi": int(r["rugi"] or 0)} for r in pj])
