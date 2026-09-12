import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ====== NANTI DIGANTI SAAT SERVER SUDAH SIAP ======
const String SERVER = "http://GANTI-IP-VPS-ANDA:8080";
const String KUNCI_API = "GANTI-KUNCI-RAHASIA-ANDA-MINIMAL-32-KARAKTER";

void main() => runApp(const SipelakApp());

void salinDanKabari(BuildContext context, String teks) {
  Clipboard.setData(ClipboardData(text: teks));
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("✅ Pesan disalin ke papan klip. Tempel di WhatsApp/medsos untuk menyebar.")));
}

class SipelakApp extends StatelessWidget {
  const SipelakApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIPELAK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.dark(
          primary: Colors.lightBlueAccent,
          secondary: Colors.indigoAccent,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const LayarPersetujuan(anak: Beranda()),
    );
  }
}

class Api {
  static Future<Map<String, dynamic>> post(String path, Map body) async {
    final r = await http
        .post(Uri.parse("$SERVER$path"),
            headers: {"Content-Type": "application/json", "X-API-Key": KUNCI_API},
            body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> get(String path) async {
    final r = await http
        .get(Uri.parse("$SERVER$path"), headers: {"X-API-Key": KUNCI_API})
        .timeout(const Duration(seconds: 15));
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
}

class LayarPersetujuan extends StatefulWidget {
  final Widget anak;
  const LayarPersetujuan({super.key, required this.anak});
  @override
  State<LayarPersetujuan> createState() => _LayarPersetujuanState();
}

class _LayarPersetujuanState extends State<LayarPersetujuan> {
  bool _cek = false;

  @override
  void initState() {
    super.initState();
    _periksa();
  }

  Future<void> _periksa() async {
    final p = await SharedPreferences.getInstance();
    if (p.getBool("setuju") == true && mounted) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => widget.anak));
    }
  }

  Future<void> _setuju() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool("setuju", true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => widget.anak));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("🛡️ SIPELAK",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Sistem Pencatatan Laporan Penipuan Mandiri",
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            const Text(
                "KETENTUAN & KEBIJAKAN PRIVASI\n\n"
                "1. SIPELAK adalah sistem pencatatan laporan dugaan penipuan yang dikelola secara mandiri.\n\n"
                "2. SIPELAK TIDAK melakukan pelacakan lokasi, penyadapan, atau pengambilan data pribadi siapa pun. Semua data berasal dari laporan sukarela pengguna.\n\n"
                "3. Identitas pelapor dianonimkan otomatis (hash). SIPELAK tidak menyimpan data pribadi pelapor secara mentah.\n\n"
                "4. Hasil analisis adalah indikasi berdasarkan laporan terkumpul, bukan vonis hukum. Verifikasi dan penegakan hukum dilakukan oleh pihak berwenang.\n\n"
                "5. Data hanya dibagikan kepada penegak hukum atas laporan resmi atau permintaan yang sah.\n\n"
                "6. Dilarang menggunakan SIPELAK untuk fitnah, doxing, atau melaporkan nomor tanpa dasar kejadian nyata.\n\n"
                "Sesuai UU No. 27 Tahun 2022 tentang Pelindungan Data Pribadi.",
                style: TextStyle(height: 1.6, fontSize: 13)),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _cek,
              onChanged: (v) => setState(() => _cek = v!),
              title: const Text("Saya membaca dan menyetujui ketentuan ini",
                  style: TextStyle(fontSize: 13)),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            FilledButton(
              onPressed: _cek ? _setuju : null,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: const Text("MASUK", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
      ),
    );
  }
}

class Beranda extends StatefulWidget {
  const Beranda({super.key});
  @override
  State<Beranda> createState() => _BerandaState();
}

class _BerandaState extends State<Beranda> {
  int _tab = 0;
  final List<Widget> _halaman = const [
    HalamanCek(),
    HalamanLapor(),
    HalamanBukti(),
    HalamanBerkas(),
    HalamanStatistik(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🛡️ SIPELAK",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: IndexedStack(index: _tab, children: _halaman),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        backgroundColor: const Color(0xFF1E293B),
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: "Cek"),
          NavigationDestination(
              icon: Icon(Icons.report_gmailerrorred), label: "Lapor"),
          NavigationDestination(icon: Icon(Icons.photo_camera), label: "Bukti"),
          NavigationDestination(icon: Icon(Icons.gavel), label: "Berkas"),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: "Statistik"),
        ],
      ),
    );
  }
}

class HalamanCek extends StatefulWidget {
  const HalamanCek({super.key});
  @override
  State<HalamanCek> createState() => _HalamanCekState();
}

class _HalamanCekState extends State<HalamanCek> {
  final _c = TextEditingController();
  Map<String, dynamic>? _hasil;
  bool _loading = false;

  Future<void> _cek() async {
    if (_c.text.trim().length < 8) return;
    setState(() {
      _loading = true;
      _hasil = null;
    });
    try {
      _hasil = await Api.post("/cek", {"nomor": _c.text.trim()});
    } catch (e) {
      _hasil = {"error": "Server tidak terjangkau. Periksa koneksi/server."};
    }
    setState(() => _loading = false);
  }

  void _share(BuildContext context) {
    final h = _hasil;
    if (h == null || h["error"] != null) return;
    final skor = (h["skor"] ?? 0) as int;
    final peringatan = skor >= 60
        ? "🔴 JANGAN transfer uang ke nomor/rekening terkait nomor ini!"
        : "🟠 Hati-hati, sudah ada laporan terkait nomor ini.";
    final pesan = "⚠️ PERINGATAN PENIPUAN ⚠️\n\n"
        "Nomor: ${h["nomor"]}\n"
        "Status: ${h["verdict"]} (skor risiko $skor/100)\n"
        "Dilaporkan oleh: ${h["korban_unik"]} korban\n"
        "Total kerugian tercatat: Rp ${h["total_kerugian"]}\n\n"
        "$peringatan\n\n"
        "🛡️ Dicek via aplikasi SIPELAK.\n"
        "Sebarluaskan agar tidak ada korban berikutnya.";
    salinDanKabari(context, pesan);
  }

  Widget _kartu(Color warna, String teks, {Widget? anak}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: warna,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: anak ??
            Text(teks, style: const TextStyle(fontSize: 14, height: 1.5)),
      );

  @override
  Widget build(BuildContext context) {
    final h = _hasil;
    final skor = h == null ? 0 : ((h["skor"] ?? 0) as int);
    final warnaVerdict =
        skor >= 60 ? Colors.red : skor >= 30 ? Colors.orange : Colors.green;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text("Periksa nomor sebelum transaksi.",
            style: TextStyle(color: Colors.white70, fontSize: 15)),
        const SizedBox(height: 16),
        TextField(
          controller: _c,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: "Masukkan nomor HP (08xx / 62xx)",
            prefixIcon: const Icon(Icons.phone),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _loading ? null : _cek,
          icon: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.shield),
          label: Text(_loading ? "MENGANALISIS..." : "CEK SEKARANG"),
          style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 20),
        if (h != null && h["error"] != null)
          _kartu(Colors.red.shade900, "⚠️ ${h["error"]}"),
        if (h != null && h["error"] == null) ...[
          _kartu(warnaVerdict.withOpacity(0.25), "",
              anak: Column(children: [
                Text("⚖️ ${h["verdict"]}",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: warnaVerdict)),
                const SizedBox(height: 10),
                ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                        value: skor / 100,
                        minHeight: 12,
                        backgroundColor: Colors.white12,
                        color: warnaVerdict)),
                const SizedBox(height: 6),
                Text("Skor Risiko: $skor/100",
                    style: const TextStyle(color: Colors.white70)),
              ])),
          const SizedBox(height: 12),
          _kartu(const Color(0xFF1E293B),
              "📌 Laporan tercatat: ${h["jumlah_laporan"]}\n👥 Korban unik: ${h["korban_unik"]}\n💰 Total kerugian: Rp ${h["total_kerugian"]}"),
          const SizedBox(height: 12),
          ...((h["flags"] as List?) ?? [])
              .map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _kartu(const Color(0xFF1E293B), f.toString()),
                  ))
              .toList(),
          if (skor >= 30) ...[
            const SizedBox(height: 4),
            FilledButton.tonalIcon(
              onPressed: () => _share(context),
              icon: const Icon(Icons.campaign),
              label: const Text("SEBARKAN PERINGATAN"),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ],
        ],
      ]),
    );
  }
}

class HalamanLapor extends StatefulWidget {
  const HalamanLapor({super.key});
  @override
  State<HalamanLapor> createState() => _HalamanLaporState();
}

class _HalamanLaporState extends State<HalamanLapor> {
  final hp = TextEditingController();
  final rek = TextEditingController();
  final nama = TextEditingController();
  final bank = TextEditingController();
  final rugi = TextEditingController();
  final kronologi = TextEditingController();
  final chat = TextEditingController();
  final pelapor = TextEditingController();
  String jenis = "jual_beli_online";
  bool _kirim = false;
  String? _pesan;

  Future<void> _kirimLaporan() async {
    if (hp.text.trim().length < 8 || kronologi.text.trim().isEmpty) {
      setState(() => _pesan = "❗ Nomor HP dan kronologi wajib diisi.");
      return;
    }
    setState(() {
      _kirim = true;
      _pesan = null;
    });
    try {
      final res = await Api.post("/lapor", {
        "nomor_hp": hp.text.trim(),
        "nomor_rekening": rek.text.trim(),
        "nama_pelaku": nama.text.trim(),
        "bank": bank.text.trim(),
        "jenis": jenis,
        "kerugian": double.tryParse(rugi.text) ?? 0,
        "kronologi": kronologi.text.trim(),
        "bukti_chat": chat.text.trim(),
        "pelapor": pelapor.text.trim(),
      });
      setState(() => _pesan =
          "✅ Laporan tersimpan (ID #${res["id"]}). Data ini memperkuat analisis untuk korban berikutnya.");
      for (final c in [hp, rek, nama, bank, rugi, kronologi, chat]) {
        c.clear();
      }
    } catch (e) {
      setState(() => _pesan = "⚠️ Gagal mengirim. Periksa server.");
    }
    setState(() => _kirim = false);
  }

  Widget _input(TextEditingController c, String hint,
          {bool angka = false, int baris = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
            controller: c,
            maxLines: baris,
            keyboardType: angka ? TextInputType.number : null,
            decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)))),
      );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text("📝 Lapor Penipu",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text("Laporkan ke database sistem Anda sendiri.",
            style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 16),
        _input(hp, "Nomor HP pelaku *"),
        _input(rek, "Nomor rekening pelaku"),
        _input(bank, "Bank / e-wallet"),
        _input(nama, "Nama yang dipakai pelaku"),
        DropdownButtonFormField<String>(
          value: jenis,
          dropdownColor: const Color(0xFF1E293B),
          decoration: const InputDecoration(labelText: "Jenis penipuan"),
          items: const [
            DropdownMenuItem(
                value: "jual_beli_online", child: Text("Jual beli online palsu")),
            DropdownMenuItem(value: "pinjol_palsu", child: Text("Pinjol palsu")),
            DropdownMenuItem(
                value: "investasi_bodong", child: Text("Investasi bodong")),
            DropdownMenuItem(value: "love_scam", child: Text("Love scam")),
            DropdownMenuItem(value: "phishing", child: Text("Phishing / link palsu")),
            DropdownMenuItem(value: "lainnya", child: Text("Lainnya")),
          ],
          onChanged: (v) => setState(() => jenis = v!),
        ),
        const SizedBox(height: 12),
        _input(rugi, "Kerugian (Rp)", angka: true),
        _input(kronologi, "Kronologi kejadian *", baris: 4),
        _input(chat, "Tempel chat pelaku (untuk deteksi modus otomatis)", baris: 3),
        _input(pelapor, "Nama/inisial Anda (dianonimkan otomatis)"),
        FilledButton.icon(
            onPressed: _kirim ? null : _kirimLaporan,
            icon: const Icon(Icons.send),
            label: const Text("KIRIM LAPORAN"),
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16))),
        if (_pesan != null)
          Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(_pesan!, style: const TextStyle(height: 1.4))),
      ]),
    );
  }
}

class HalamanBukti extends StatefulWidget {
  const HalamanBukti({super.key});
  @override
  State<HalamanBukti> createState() => _HalamanBuktiState();
}

class _HalamanBuktiState extends State<HalamanBukti> {
  final _lapId = TextEditingController();
  XFile? _foto;
  String? _pesan;
  String? _hash;
  bool _kirim = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _ambilFoto() async {
    final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (f != null) {
      setState(() {
        _foto = f;
        _hash = null;
        _pesan = null;
      });
    }
  }

  Future<void> _kirimBukti() async {
    if (_foto == null) {
      setState(() => _pesan = "❗ Pilih foto bukti dulu.");
      return;
    }
    setState(() {
      _kirim = true;
      _pesan = null;
    });
    try {
      final req = http.MultipartRequest("POST", Uri.parse("$SERVER/bukti_file"))
        ..headers["X-API-Key"] = KUNCI_API
        ..fields["laporan_id"] =
            _lapId.text.trim().isEmpty ? "0" : _lapId.text.trim()
        ..files.add(await http.MultipartFile.fromPath("file", _foto!.path));
      final res = await req.send().timeout(const Duration(seconds: 30));
      final data = jsonDecode(await res.stream.bytesToString());
      setState(() {
        _hash = data["hash_sha256"];
        _pesan = "✅ Bukti tersegel permanen di server Anda.";
      });
    } catch (e) {
      setState(() => _pesan = "⚠️ Gagal kirim. Periksa server.");
    }
    setState(() => _kirim = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text("📸 Upload Bukti",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text(
            "Foto bukti transfer/chat di-hash SHA-256 otomatis sehingga keasliannya bisa diverifikasi penyidik.",
            style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 16),
        TextField(
          controller: _lapId,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
              hintText: "ID laporan (opsional)",
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        ),
        const SizedBox(height: 12),
        if (_foto != null)
          FutureBuilder<Uint8List>(
            future: _foto!.readAsBytes(),
            builder: (context, snap) => snap.hasData
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(snap.data!,
                        height: 220, width: double.infinity, fit: BoxFit.cover))
                : const SizedBox(
                    height: 220, child: Center(child: CircularProgressIndicator())),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
            onPressed: _ambilFoto,
            icon: const Icon(Icons.photo_library),
            label: const Text("PILIH FOTO BUKTI")),
        const SizedBox(height: 10),
        FilledButton.icon(
            onPressed: _kirim ? null : _kirimBukti,
            icon: const Icon(Icons.verified),
            label: Text(_kirim ? "MENYEGEL..." : "SEGEL & KIRIM BUKTI"),
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16))),
        if (_pesan != null)
          Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(_pesan!, style: const TextStyle(height: 1.4))),
        if (_hash != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SelectableText("SHA-256: $_hash",
                style: const TextStyle(
                    fontFamily: "monospace",
                    fontSize: 11,
                    color: Colors.lightBlueAccent)),
          ),
      ]),
    );
  }
}

class HalamanBerkas extends StatefulWidget {
  const HalamanBerkas({super.key});
  @override
  State<HalamanBerkas> createState() => _HalamanBerkasState();
}

class _HalamanBerkasState extends State<HalamanBerkas> {
  final _nomor = TextEditingController();
  Map<String, dynamic>? _hasil;
  bool _proses = false;

  Future<void> _buat() async {
    if (_nomor.text.trim().length < 8) return;
    setState(() {
      _proses = true;
      _hasil = null;
    });
    try {
      _hasil = await Api.get("/berkas/${_nomor.text.trim()}");
    } catch (e) {
      _hasil = {"error": "Server tidak terjangkau atau berkas belum ada."};
    }
    setState(() => _proses = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text("⚖️ Berkas Hukum",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text(
            "Buat paket bukti tersegel SHA-256 siap diserahkan ke kepolisian atau bank.",
            style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 16),
        TextField(
            controller: _nomor,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
                hintText: "Nomor HP terlapor",
                prefixIcon: const Icon(Icons.gavel),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)))),
        const SizedBox(height: 12),
        FilledButton.icon(
            onPressed: _proses ? null : _buat,
            icon: const Icon(Icons.folder_zip),
            label: Text(_proses ? "MENYUSUN BERKAS..." : "BUAT BERKAS HUKUM"),
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16))),
        const SizedBox(height: 16),
        if (_hasil != null && _hasil!["error"] != null)
          Text("⚠️ ${_hasil!["error"]}",
              style: const TextStyle(color: Colors.redAccent)),
        if (_hasil != null && _hasil!["isi_surat"] != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("✅ Berkas: ${_hasil!["file_zip"]}",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  "Korban: ${_hasil!["jumlah_korban"]} • Kerugian: Rp ${_hasil!["total_kerugian"]} • Bukti: ${_hasil!["jumlah_bukti"]}",
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 10),
              SelectableText(_hasil!["isi_surat"],
                  style: const TextStyle(
                      fontFamily: "monospace", fontSize: 11, height: 1.4)),
            ]),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
              onPressed: () => salinDanKabari(context,
                  "Berkas hukum SIPELAK untuk nomor ${_nomor.text.trim()} siap di server: ${_hasil!["file_zip"]}"),
              icon: const Icon(Icons.share),
              label: const Text("BAGIKAN INFO BERKAS")),
        ],
      ]),
    );
  }
}

class HalamanStatistik extends StatefulWidget {
  const HalamanStatistik({super.key});
  @override
  State<HalamanStatistik> createState() => _HalamanStatistikState();
}

class _HalamanStatistikState extends State<HalamanStatistik> {
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    try {
      final d = await Api.get("/statistik");
      if (mounted) setState(() => _data = d);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final jenis = (_data!["per_jenis"] as List?) ?? [];
    return RefreshIndicator(
      onRefresh: _muat,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _kotak("⛔", "Total nomor di blacklist", "${_data!["total_blacklist"]}"),
          const SizedBox(height: 12),
          ...jenis.map((j) => _kotak("📁", "${j["jenis"]}",
              "${j["kasus"]} kasus • Rp ${j["rugi"]}")),
        ],
      ),
    );
  }

  Widget _kotak(String ikon, String judul, String nilai) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12)),
        child: Row(children: [
          Text(ikon, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(judul, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(nilai, style: const TextStyle(color: Colors.white60, fontSize: 13)),
          ])),
        ]),
      );
}
