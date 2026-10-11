# n8n-agent — kaldırıldı

Kullanıcının talebiyle agent.ps1 ve setup.ps1 kaldırıldı. Bu sürüm agent kurmaz veya başlatmaz. Eski Git sürümleri ve yerel kopyalar hâlâ çalışabilir.

## Windows bilgisayardan kaldırma

1. n8n Settings > n8n API bölümünde bu agent için kullanılan API anahtarını iptal edin. Bu işlem GitHub'dan yapılamaz.
2. uninstall.ps1 dosyasını indirin, inceleyin ve agent'ın kurulduğu Windows hesabında çalıştırın:
   powershell.exe -NoProfile -File .\uninstall.ps1
   Özel kurulum yolu için: .\uninstall.ps1 -InstallDir 'D:\n8n-agent'
3. Windows'u yeniden başlatıp agent sürecinin ve Başlangıç girdisinin bulunmadığını doğrulayın.

Betik mevcut kullanıcıya ait n8n-agent.cmd Başlangıç girdisini kaldırır, belirtilen agent.ps1 dosyasını çalıştıran PowerShell süreçlerini durdurur ve dosyayı siler; yerel n8n-key.txt dosyasını siler. Diğer workflow'ları, görev dosyalarını ve n8n sunucusunu silmez. Farklı hesap, servis veya Zamanlanmış Görev üzerinden yapılmış ek kurulumlar ayrıca kaldırılmalıdır. API anahtarını iptal etmek eski kopyaların o anahtarla API erişimini de keser.

## Güvenlik incelemesi ve gelecekteki tasarım önerisi

- Anahtar: setup.ps1, ConvertFrom-SecureString ile Windows DPAPI kullanıyordu; düz metin değildi. Aynı kullanıcı altındaki süreçler çözebilir. Kullanıcıya özel ACL, en az yetki, süreli anahtar ve düzenli iptal/yenileme gerekir. Anahtar repoya veya loga yazılmamalı.
- URL: sabit localhost yerine doğrulanan N8N_API_BASE_URL yapılandırması; yalnız loopback için HTTP, uzaktaki sunucu için HTTPS. Yönlendirmelerde anahtarın başka sunucuya aktarılması engellenmeli.
- Tekrar deneme: istek zaman aşımı, üst sınır, üstel bekleme ve rastgele gecikme; 429 için Retry-After. 401/403 ve hatalı görevlerde sürekli deneme yapılmamalı. POST isteği belirsiz sonuçla başarısızsa tekrar oluşturmadan önce uzlaştırılmalı; çift workflow riski var.
- Log: ham Exception.Message, git çıktısı, yanıt gövdesi, header ve görev içeriği yerine izin verilen olay kodu/HTTP durum kodu; boyut sınırı ve rotasyon. Görev adları gibi dış girdiler satır sonlarından arındırılmalı.
- Dağıtım: gizli otomatik başlangıç ve ExecutionPolicy Bypass varsayılan olmamalı; açık onaylı kurulum, tek sefer çalışma ve iptal desteği gerekir. Her döngüde git pull yerine gözden geçirilmiş sabit sürüm kullanılmalı; git çıkış kodu kontrolü ve try/finally ile konum geri yükleme gerekir.
- Görevler: şema doğrulaması, sayfalama ve aynı isimli workflow belirsizliğini reddetme; atomik durum yazımı. Bozuk processed.json sessizce sıfırlanmamalı; bu görevleri yeniden uygulayabilir.

## Örnek görev

examples/tasks/example.json yalnız dokümantasyon örneğidir; çalışan tasks kuyruğuna konmadı. Mevcut tasks dosyaları korunmuştur. Agent yeniden uygulanmadı.
