# NEXUS kurulumu

Windows 10/11 x64 ve Windows PowerShell 5.1+ için:

```powershell
[Net.ServicePointManager]::SecurityProtocol=3072;irm https://raw.githubusercontent.com/krds0814-dev/nexus-kurulum/main/kur.ps1 -ea Stop|iex
```

Bu depo kurulum giriş betiğini ve MIT lisanslı resmî GitHub CLI paketinin
değiştirilmemiş kopyasını içerir. NEXUS ve Forge Studio uygulama
kaynakları özel depolarda kalır. GitHub hesabınızın bu depolara erişimi gerekir.
Parola, bot anahtarı ve kullanıcı ayarları bu depoda tutulmaz.

Git veya Python'u önceden kurmak gerekmez. Betik doğrulanmış GitHub CLI'yi hazırlar,
GitHub girişini ve Türkçe kurulum sihirbazını başlatır. Model veya video üretmez.
GitHub Releases erişilemiyorsa da hazırlanabilmesi için CLI paketi önce bu
deponun `raw.githubusercontent.com` adresinden, sabit bir commit üzerinden alınır.
`vendor/github-cli.json` resmî kaynak ve SHA-256 bilgisini; `vendor/LICENSE.github-cli.txt`
dağıtım lisansını içerir. Paket, resmî yayımlanan SHA-256 ile doğrulanmadan çalıştırılmaz.
Geçici bağlantı hatalarında yeniden deneme ve resmî alternatif indirme yolları kullanılır.
İndirme başarısızsa resmî API, önbelleksiz bağlantı, ardından varsa Windows Paket
Yöneticisi ile otomatik ZIP indirmesi denenir. Sistem kurulumu yapılmaz; indirilen
dosyanın sabit SHA-256 özeti ayrıca doğrulanır. Tüm yollar erişilemezse aynı kısa
komutla daha sonra tekrar denenebilir; elle GitHub CLI kurulması istenmez.

`bootstrap-manifest.json`, giriş betiğinin SHA-256 özetini ve kaynak bilgisini taşır.
Uygulama kaynakları, hesaplar, modeller ve videolar bu depoda yayımlanmaz.
