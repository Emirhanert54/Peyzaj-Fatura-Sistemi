import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(const PeyzajApp());
}

class PeyzajApp extends StatelessWidget {
  const PeyzajApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peyzaj Fatura Yönetimi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const AnaEkran(),
    );
  }
}

class AnaEkran extends StatefulWidget {
  const AnaEkran({super.key});

  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  // Para Birimi Ayarları
  String seciliParaBirimi = "€";
  final List<String> paraBirimleri = ["€", "₺", "\$", "£"];

  final List<Map<String, dynamic>> varsayilanHizmetler = [
    {"ad": "Çim Biçme (m²)", "fiyat": 5.0},
    {"ad": "Ağaç Budama (Adet)", "fiyat": 25.0},
    {"ad": "Rulo Çim Serimi (m²)", "fiyat": 15.0},
    {"ad": "Gübreleme (m²)", "fiyat": 3.5},
    {"ad": "Bahçe Temizliği (Saat)", "fiyat": 40.0},
    {"ad": "Yabani Ot Temizliği (m²)", "fiyat": 4.0},
    {"ad": "Fidan Dikimi (Adet)", "fiyat": 30.0},
    {"ad": "Çit Kesimi ve Düzenleme (Metre)", "fiyat": 12.0},
  ];

  List<Map<String, dynamic>> hizmetler = [];
  List<Map<String, dynamic>> sepet = [];

  final TextEditingController musteriAdController = TextEditingController();
  final TextEditingController musteriAdresController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    final prefs = await SharedPreferences.getInstance();
    final String? kaydedilenVeri = prefs.getString('kayitli_hizmetler');
    
    setState(() {
      if (kaydedilenVeri != null) {
        List<dynamic> cozulmus = json.decode(kaydedilenVeri);
        hizmetler = cozulmus.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        hizmetler = List.from(varsayilanHizmetler);
      }
    });
  }

  Future<void> _verileriKaydet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('kayitli_hizmetler', json.encode(hizmetler));
  }

  double get genelToplam {
    return sepet.fold(0, (toplam, islem) => toplam + (islem["fiyat"] * islem["adet"]));
  }

  String _pdfMetin(String text) {
    return text.replaceAll('ç', 'c').replaceAll('Ç', 'C').replaceAll('ğ', 'g').replaceAll('Ğ', 'G')
        .replaceAll('ı', 'i').replaceAll('İ', 'I').replaceAll('ö', 'o').replaceAll('Ö', 'O')
        .replaceAll('ş', 's').replaceAll('Ş', 'S').replaceAll('ü', 'u').replaceAll('Ü', 'U');
  }

  String _pdfParaBirimi() {
    switch (seciliParaBirimi) {
      case '₺': return 'TL';
      case '€': return 'Euro';
      case '\$': return 'USD';
      case '£': return 'Sterlin';
      default: return seciliParaBirimi;
    }
  }

  void _yeniHizmetEklePenceresi() {
    final adController = TextEditingController();
    final fiyatController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Yeni Hizmet/Ürün Ekle"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: adController, decoration: const InputDecoration(labelText: "Hizmet Adı")),
              const SizedBox(height: 10),
              TextField(controller: fiyatController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Birim Fiyatı ($seciliParaBirimi)")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              onPressed: () {
                if (adController.text.isNotEmpty && fiyatController.text.isNotEmpty) {
                  setState(() {
                    hizmetler.add({
                      "ad": adController.text,
                      "fiyat": double.tryParse(fiyatController.text.replaceAll(',', '.')) ?? 0.0,
                    });
                  });
                  _verileriKaydet();
                  Navigator.pop(context);
                }
              },
              child: const Text("Kaydet"),
            ),
          ],
        );
      },
    );
  }

  void _fiyatGuncellePenceresi(int index) {
    final fiyatController = TextEditingController(text: hizmetler[index]["fiyat"].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("${hizmetler[index]["ad"]} \nFiyatını Güncelle", textAlign: TextAlign.center),
          content: TextField(
            controller: fiyatController, 
            keyboardType: TextInputType.number, 
            decoration: InputDecoration(labelText: "Yeni Fiyat ($seciliParaBirimi)")
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              onPressed: () {
                if (fiyatController.text.isNotEmpty) {
                  setState(() {
                    hizmetler[index]["fiyat"] = double.tryParse(fiyatController.text.replaceAll(',', '.')) ?? hizmetler[index]["fiyat"];
                    
                    // Sepette varsa oradaki fiyatı da güncelle
                    for (var item in sepet) {
                      if (item["ad"] == hizmetler[index]["ad"]) {
                        item["fiyat"] = hizmetler[index]["fiyat"];
                      }
                    }
                  });
                  _verileriKaydet();
                  Navigator.pop(context);
                }
              },
              child: const Text("Güncelle"),
            ),
          ],
        );
      },
    );
  }

  void _hizmetSil(int index) {
    setState(() {
      hizmetler.removeAt(index);
    });
    _verileriKaydet();
  }

  Future<void> _pdfOlusturVeYazdir() async {
    final pdf = pw.Document();
    final bugun = DateFormat('dd.MM.yyyy').format(DateTime.now());
    final musteriAd = _pdfMetin(musteriAdController.text.isEmpty ? "Belirtilmedi" : musteriAdController.text);
    final musteriAdres = _pdfMetin(musteriAdresController.text.isEmpty ? "-" : musteriAdresController.text);
    final pb = _pdfParaBirimi();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("PEYZAJ VE BAHCE ISLERI", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                      pw.SizedBox(height: 5),
                      pw.Text("Musteri Faturasi / Hizmet Dokumu", style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                    ]
                  ),
                  pw.Text("Tarih: $bugun", style: const pw.TextStyle(fontSize: 12)),
                ]
              ),
              pw.SizedBox(height: 25),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(color: PdfColors.grey100, border: pw.Border.all(color: PdfColors.grey300)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("MUSTERI BILGILERI", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey600)),
                    pw.SizedBox(height: 5),
                    pw.Text("Sayin: $musteriAd", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    pw.SizedBox(height: 3),
                    pw.Text("Adres/Iletisim: $musteriAdres", style: const pw.TextStyle(fontSize: 12)),
                  ]
                )
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.green700),
                cellAlignment: pw.Alignment.centerLeft,
                headers: ['Islem', 'Adet', 'Birim Fiyat', 'Toplam'],
                data: sepet.map((islem) {
                  return [
                    _pdfMetin(islem["ad"]),
                    '${islem["adet"]}x',
                    '${islem["fiyat"].toStringAsFixed(2)} $pb',
                    '${(islem["fiyat"] * islem["adet"]).toStringAsFixed(2)} $pb',
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 30),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text("GENEL TOPLAM: ", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text("${genelToplam.toStringAsFixed(2)} $pb", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                  ]
                )
              ),
              pw.Expanded(child: pw.SizedBox()),
              pw.Center(
                child: pw.Text("Bizi tercih ettiginiz icin tesekkur ederiz.", style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600))
              )
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Fatura_${musteriAdController.text.replaceAll(' ', '_')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peyzaj ve Bahçe İşleri - Yönetim Sistemi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          Center(child: const Text("Para Birimi: ", style: TextStyle(fontSize: 14))),
          DropdownButton<String>(
            value: seciliParaBirimi,
            dropdownColor: Colors.green.shade800,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            underline: Container(), // Çizgiyi gizle
            items: paraBirimleri.map((String birim) {
              return DropdownMenuItem<String>(value: birim, child: Text(birim));
            }).toList(),
            onChanged: (String? yeniBirim) {
              if (yeniBirim != null) {
                setState(() {
                  seciliParaBirimi = yeniBirim;
                });
              }
            },
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: Row(
        children: [
          // SOL TARAF
          Expanded(
            flex: 3, 
            child: Container(
              color: Colors.grey.shade100,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.white,
                    child: ElevatedButton.icon(
                      onPressed: _yeniHizmetEklePenceresi,
                      icon: const Icon(Icons.add_circle),
                      label: const Text("YENİ HİZMET/ÜRÜN EKLE", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: hizmetler.length,
                      itemBuilder: (context, index) {
                        final hizmet = hizmetler[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            onTap: () {
                              setState(() {
                                int varOlanIndex = sepet.indexWhere((item) => item["ad"] == hizmet["ad"]);
                                if (varOlanIndex != -1) {
                                  sepet[varOlanIndex]["adet"] += 1;
                                } else {
                                  sepet.add({
                                    "ad": hizmet["ad"],
                                    "fiyat": hizmet["fiyat"],
                                    "adet": 1,
                                  });
                                }
                              });
                            },
                            leading: const Icon(Icons.grass, color: Colors.green),
                            title: Text(hizmet["ad"].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Text("${hizmet["fiyat"].toStringAsFixed(2)} $seciliParaBirimi", style: const TextStyle(fontSize: 15, color: Colors.green, fontWeight: FontWeight.bold)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  tooltip: "Fiyatı Güncelle",
                                  onPressed: () => _fiyatGuncellePenceresi(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  tooltip: "Hizmeti Sil",
                                  onPressed: () => _hizmetSil(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // SAĞ TARAF
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.green.shade50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("MÜŞTERİ BİLGİLERİ (Faturada Görünecek)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                        const SizedBox(height: 10),
                        TextField(controller: musteriAdController, decoration: const InputDecoration(labelText: "Müşteri Adı / Soyadı", border: OutlineInputBorder(), isDense: true)),
                        const SizedBox(height: 10),
                        TextField(controller: musteriAdresController, decoration: const InputDecoration(labelText: "Adres / İletişim Numarası", border: OutlineInputBorder(), isDense: true)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: Colors.green.shade100,
                    width: double.infinity,
                    child: const Text("Sepet", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: sepet.isEmpty
                        ? const Center(child: Text("Sepet şu an boş.\nListeden bir öğeye tıklayarak ekleyin.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)))
                        : ListView.builder(
                            itemCount: sepet.length,
                            itemBuilder: (context, index) {
                              final islem = sepet[index];
                              final double satirToplami = islem["fiyat"] * islem["adet"];
                              return ListTile(
                                title: Text("${islem["adet"]}x  ${islem["ad"]}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("${satirToplami.toStringAsFixed(2)} $seciliParaBirimi", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 22),
                                      onPressed: () {
                                        setState(() {
                                          if (sepet[index]["adet"] > 1) {
                                            sepet[index]["adet"] -= 1;
                                          } else {
                                            sepet.removeAt(index);
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(color: Colors.green.shade50, border: Border(top: BorderSide(color: Colors.green.shade200, width: 2))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("TOPLAM:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text("${genelToplam.toStringAsFixed(2)} $seciliParaBirimi", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: sepet.isEmpty ? null : _pdfOlusturVeYazdir,
                          icon: const Icon(Icons.print),
                          label: const Padding(padding: EdgeInsets.symmetric(vertical: 12.0), child: Text("FİŞ / PDF OLUŞTUR", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}