# Reviewed public kur.ps1 source and readable long-command fallback.
& {
    $ErrorActionPreference='Stop';
    $nexusMachine=if($env:PROCESSOR_ARCHITEW6432){$env:PROCESSOR_ARCHITEW6432}else{$env:PROCESSOR_ARCHITECTURE};
    if($nexusMachine -ne 'AMD64'){throw 'Bu NEXUS dagitimi Windows x64 (AMD64) gerektirir. ARM64 ve 32-bit icin tum hazir bagimlilik paketleri bulunmadigindan kurulum baslatilmadi.';};
    $nexusTemp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\');
    $nexusScratch=Join-Path $nexusTemp ('nexus-entry-'+[Guid]::NewGuid().ToString('N'));
    $nexusOldPath=$env:Path;
    New-Item -ItemType Directory -Path $nexusScratch | Out-Null;
    try {
        $nexusCommand=Get-Command gh.exe -ErrorAction SilentlyContinue;
        if($nexusCommand){ $nexusGhPath=$nexusCommand.Source; } else {
            $nexusArchitecture=if($env:PROCESSOR_ARCHITEW6432){$env:PROCESSOR_ARCHITEW6432}else{$env:PROCESSOR_ARCHITECTURE};
            switch($nexusArchitecture.ToUpperInvariant()) {
                'AMD64' {$nexusArch='amd64';$nexusAsset='679195750';$nexusExpected='98d0cfa794721665d7973dd728c78aff7bd836d58f10f6d7a03568eccb0a22e0';}
                'ARM64' {$nexusArch='arm64';$nexusAsset='679195799';$nexusExpected='197211c98687d7770ac331fe8a3b6c198c389108c1536cdbedf659fe4703e484';}
                'X86' {$nexusArch='386';$nexusAsset='679195741';$nexusExpected='e18001aaa03da36635626b3557947a886704d67f532292577c5945ad0535f6eb';}
                default {throw 'Desteklenmeyen Windows mimarisi.';}
            };
            $nexusZip=Join-Path $nexusScratch 'gh.zip';
            $nexusUrl='https://github.com/cli/cli/releases/download/v2.103.3/gh_2.103.3_windows_'+$nexusArch+'.zip';
            $nexusApiUrl='https://api.github.com/repos/cli/cli/releases/assets/'+$nexusAsset;
            $nexusCurl=Get-Command curl.exe -CommandType Application -ErrorAction SilentlyContinue;
            Write-Host 'Resmi tasinabilir GitHub CLI indiriliyor...';
            [Net.ServicePointManager]::SecurityProtocol=[Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12;
            for($nexusAttempt=1;$nexusAttempt -le 4;$nexusAttempt++) {
                try {
                    Remove-Item -LiteralPath $nexusZip -Force -ErrorAction SilentlyContinue;
                    $nexusDownloadUrl=if($nexusAttempt -le 2){$nexusUrl}else{$nexusApiUrl};
                    if($nexusCurl -and ($nexusAttempt % 2 -eq 0)) {
                        & $nexusCurl.Source --fail --location --silent --show-error --proto '=https' --proto-redir '=https' --connect-timeout 20 --max-time 120 --header 'Accept: application/octet-stream' --header 'User-Agent: NEXUS-Installer' --output $nexusZip $nexusDownloadUrl;
                        if($LASTEXITCODE -ne 0){throw ('curl indirme hatasi (kod '+$LASTEXITCODE+').');};
                    } else {
                        Invoke-WebRequest -Uri $nexusDownloadUrl -OutFile $nexusZip -UseBasicParsing -Headers @{'Accept'='application/octet-stream';'User-Agent'='NEXUS-Installer'} -TimeoutSec 120 -ErrorAction Stop;
                    };
                    if(-not (Test-Path -LiteralPath $nexusZip) -or (Get-Item -LiteralPath $nexusZip).Length -eq 0){throw 'Indirme bos veya eksik.';};
                    $nexusHasher=[Security.Cryptography.SHA256]::Create();
                    $nexusStream=[IO.File]::OpenRead($nexusZip);
                    try {$nexusHash=[BitConverter]::ToString($nexusHasher.ComputeHash($nexusStream)).Replace('-','');} finally {$nexusStream.Dispose();$nexusHasher.Dispose();};
                    if($nexusHash -ne $nexusExpected){throw 'GitHub CLI SHA-256 dogrulamasi basarisiz; dosya calistirilmadi.';};
                    break;
                } catch {
                    $nexusFailure=$_.Exception.Message;
                    Remove-Item -LiteralPath $nexusZip -Force -ErrorAction SilentlyContinue;
                    Write-Host ('Indirme hatasi: '+$nexusFailure);
                    if($nexusAttempt -eq 4){throw ('GitHub CLI indirilemedi (4 deneme, resmi indirme ve API adresleri). Son hata: '+$nexusFailure+' Tarayicidan https://cli.github.com adresindeki resmi GitHub CLI kurucusunu kullanip PowerShell penceresini yeniden acabilirsiniz. NEXUS kurulumu baslatilmadi.');};
                    $nexusDelay=[int][Math]::Pow(2,$nexusAttempt);
                    Write-Host ('GitHub indirmesi tamamlanamadi; '+$nexusDelay+' saniye sonra yeniden deneniyor ('+$nexusAttempt+'/4)...');
                    Start-Sleep -Seconds $nexusDelay;
                };
            };
            Add-Type -AssemblyName System.IO.Compression.FileSystem;
            $nexusPortable=Join-Path $nexusScratch 'portable';
            $nexusArchive=[IO.Compression.ZipFile]::OpenRead($nexusZip);
            try {
                foreach($nexusEntry in $nexusArchive.Entries){
                    $nexusCandidate=[IO.Path]::GetFullPath((Join-Path $nexusPortable $nexusEntry.FullName));
                    if(-not $nexusCandidate.StartsWith($nexusPortable+'\',[StringComparison]::OrdinalIgnoreCase) -or (($nexusEntry.ExternalAttributes -shr 16) -band 0xF000) -eq 0xA000){throw 'Guvenli olmayan GitHub CLI arsivi.';};
                };
            } finally {$nexusArchive.Dispose();};
            [IO.Compression.ZipFile]::ExtractToDirectory($nexusZip,$nexusPortable);
            $nexusExecutables=@(Get-ChildItem -LiteralPath $nexusPortable -Recurse -File -Filter gh.exe);
            if($nexusExecutables.Count -ne 1){throw 'GitHub CLI dosyasi bulunamadi.';};
            $nexusGhPath=$nexusExecutables[0].FullName;
            $env:Path=(Split-Path $nexusGhPath -Parent)+';'+$nexusOldPath;
        };
        $nexusSignedIn=$false;
        try {& $nexusGhPath auth status --hostname github.com *> $null;$nexusSignedIn=($LASTEXITCODE -eq 0);} catch {$nexusSignedIn=$false;};
        if(-not $nexusSignedIn){
            Write-Host 'GitHub girisi: ekrandaki tek kullanimlik kodu https://github.com/login/device adresine yazin. Git kurulumu veya Git entegrasyonu gerekmez.';
            $nexusOldPrompt=$env:GH_PROMPT_DISABLED;
            try {
                $env:GH_PROMPT_DISABLED='1';
                & $nexusGhPath auth login --hostname github.com --web --git-protocol https;
                $nexusLoginExit=$LASTEXITCODE;
            } finally {$env:GH_PROMPT_DISABLED=$nexusOldPrompt;};
            if($nexusLoginExit -ne 0){
                & $nexusGhPath auth status --hostname github.com *> $null;
                if($LASTEXITCODE -ne 0){throw 'GitHub girisi tamamlanamadi.';};
            };
        };
        $nexusCode=& $nexusGhPath api --hostname github.com repos/krds0814-dev/NEXUS_AI/contents/tools/install_from_github.ps1 --jq .content;
        if($LASTEXITCODE -ne 0){throw 'Ozel depoya erisilemiyor.';};
        $nexusScript=Join-Path $nexusScratch 'install-from-github.ps1';
        [IO.File]::WriteAllBytes($nexusScript,[Convert]::FromBase64String(($nexusCode -join '')));
        $nexusDevCode=& $nexusGhPath api --hostname github.com repos/krds0814-dev/NEXUS_AI/contents/tools/development_setup.ps1 --jq .content;
        if($LASTEXITCODE -ne 0){throw 'Gelistirme kurulum kaynagi indirilemedi.';};
        [IO.File]::WriteAllBytes((Join-Path $nexusScratch 'development_setup.ps1'),[Convert]::FromBase64String(($nexusDevCode -join '')));
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $nexusScript;
        if($LASTEXITCODE -ne 0){throw 'Kurulum tamamlanamadi.';};
    } finally {
        $env:Path=$nexusOldPath;
        $nexusResolved=[IO.Path]::GetFullPath($nexusScratch);
        if((Split-Path $nexusResolved -Parent) -ne $nexusTemp -or (Split-Path $nexusResolved -Leaf) -notlike 'nexus-entry-*'){throw 'Guvenli olmayan temizlik hedefi.';};
        if((Get-Item -LiteralPath $nexusResolved).Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Temizlik klasoru baglantiya donustu.';};
        for($nexusCleanup=1;$nexusCleanup -le 5;$nexusCleanup++) {
            try {Remove-Item -LiteralPath $nexusResolved -Recurse -Force -ErrorAction Stop;break;} catch {
                if($nexusCleanup -eq 5){Write-Warning ('Gecici kurulum dosyalari halen kilitli; asil islem sonucu korundu. Daha sonra silinebilir: '+$nexusResolved);} else {Start-Sleep -Milliseconds 200;};
            };
        };
    };
}
