# 🌿 Peyzaj ve Bahçe İşleri - PDF Fatura Yönetim Sistemi

Peyzaj mimarları, bahçıvanlar ve tarım işletmeleri için Flutter ile geliştirilmiş, anlık PDF fatura ve teklif oluşturabilen masaüstü/tablet uyumlu yönetim uygulaması.

## 🚀 Teknolojiler
- **UI Framework:** Flutter (Dart)
- **Yerel Depolama:** Shared Preferences (Hizmet ve fiyat hafızası)
- **PDF Motoru:** `pdf` ve `printing` paketleri
- **State Management:** Ephemeral State (`setState`)

## ✨ Öne Çıkan Özellikler
- **Dinamik Sepet Yönetimi:** Çim biçme, ağaç budama gibi hizmetlerin birim fiyat ve adet bazlı anlık hesaplanması.
- **Canlı PDF Oluşturma:** Hazırlanan sepetin, müşteri bilgileriyle birlikte kurumsal bir A4 PDF faturasına dönüştürülmesi ve doğrudan yazıcıya gönderilebilmesi.
- **Kalıcı Veri:** Kullanıcının eklediği özel hizmetlerin veya güncellediği fiyatların cihaz hafızasında tutulması.
- **Akıllı Karakter Dönüşümü:** PDF oluşturma sırasında Türkçe karakterlerin (UTF-8) font hatası yaratmaması için özel string manipülasyonu.
- **Çoklu Para Birimi:** TL, Euro, Dolar ve Sterlin desteği.

## 📸 Uygulama Görselleri

### Ana Arayüz ve Sepet Yönetimi
![Ana Ekran](images/arayuz.png)

### PDF Çıktı ve Yazdırma Modülü
![Yazdırma](images/print.png)

### Oluşturulan Kurumsal Fatura (PDF)
![PDF Fatura](images/pdf.png)