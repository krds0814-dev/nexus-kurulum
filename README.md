# NEXUS kurulumu

Windows 10/11 x64 ve Windows PowerShell 5.1+ için:

```powershell
[Net.ServicePointManager]::SecurityProtocol=3072;irm https://raw.githubusercontent.com/krds0814-dev/nexus-kurulum/main/kur.ps1 -ea Stop|iex
```

Bu depo yalnızca kurulum giriş betiğini içerir. NEXUS ve Forge Studio uygulama
kaynakları özel depolarda kalır. GitHub hesabınızın bu depolara erişimi gerekir.
Parola, bot anahtarı ve kullanıcı ayarları bu depoda tutulmaz.

Git veya Python'u önceden kurmak gerekmez. Betik doğrulanmış GitHub CLI'yi hazırlar,
GitHub girişini ve Türkçe kurulum sihirbazını başlatır. Model veya video üretmez.
Geçici bağlantı hatalarında yeniden deneme ve resmî alternatif indirme yolları kullanılır.

`bootstrap-manifest.json`, giriş betiğinin SHA-256 özetini ve kaynak bilgisini taşır.
Uygulama kaynakları, hesaplar, modeller ve videolar bu depoda yayımlanmaz.
