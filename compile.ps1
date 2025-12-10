# === SCRIPT COMPLETO DE CONSTRUCCIÓN ===
Write-Host "=== CONSTRUYENDO ADVANCELOW ===" -ForegroundColor Cyan
Write-Host "Versión: 1.0.0" -ForegroundColor Yellow
Write-Host "Propiedad: NKZ" -ForegroundColor Yellow
Write-Host "Uso: Educativo/Laboratorio" -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Cyan

# 1. Configurar versiones CORRECTAS
@"
# VERSIONES CONFIRMADAS
minecraft_version=1.21.8
yarn_mappings=1.21.8+build.1
loader_version=0.15.11
fabric_version=0.129.0+1.21.8

# Configuración del mod
mod_version=1.0.0
maven_group=com.nkz
archives_base_name=advancelow
"@ | Out-File -FilePath gradle.properties -Encoding UTF8 -Force

Write-Host "✓ gradle.properties configurado" -ForegroundColor Green

# 2. Limpiar
Write-Host "`nLimpiando cache..." -ForegroundColor Cyan
.\gradlew --stop 2>&1 | Out-Null
Remove-Item -Recurse -Force .gradle, build -ErrorAction SilentlyContinue

# 3. Verificar estructura
Write-Host "`nVerificando estructura..." -ForegroundColor Cyan
$requiredFiles = @(
    "src\main\java\com\nkz\advancelow\AdvanceLow.java",
    "src\main\java\com\nkz\advancelow\AdvanceLowClient.java",
    "src\main\java\com\nkz\advancelow\mixin\AttackReachMixin.java",
    "src\main\resources\fabric.mod.json",
    "src\main\resources\advancelow.mixins.json"
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "✓ $file" -ForegroundColor Green
    } else {
        Write-Host "✗ FALTANTE: $file" -ForegroundColor Red
    }
}

# 4. Construir
Write-Host "`nConstruyendo mod..." -ForegroundColor Cyan
Write-Host "Esto puede tomar varios minutos la primera vez..." -ForegroundColor Yellow

$buildResult = .\gradlew build --no-daemon --stacktrace 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n=== CONSTRUCCIÓN EXITOSA ===" -ForegroundColor Green
    
    # Mostrar información del JAR
    $jarFile = Get-ChildItem "build\libs\advancelow-*.jar" | Select-Object -First 1
    if ($jarFile) {
        Write-Host "✓ JAR creado: $($jarFile.Name)" -ForegroundColor Green
        Write-Host "✓ Tamaño: $([math]::Round($jarFile.Length/1KB, 2)) KB" -ForegroundColor Green
        Write-Host "✓ Ubicación: $($jarFile.FullName)" -ForegroundColor Green
        
        # Verificar contenido
        Write-Host "`nContenido del JAR:" -ForegroundColor Cyan
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [System.IO.Compression.ZipFile]::OpenRead($jarFile.FullName)
        $zip.Entries.Name | Where-Object { $_ -match "\.class$" } | Select-Object -First 10 | ForEach-Object {
            Write-Host "  • $_" -ForegroundColor Gray
        }
        $zip.Dispose()
    }
    
    Write-Host "`n=== INSTALACIÓN ===" -ForegroundColor Cyan
    Write-Host "1. Copia el JAR a: .minecraft/mods/" -ForegroundColor Yellow
    Write-Host "2. Asegúrate de tener Fabric API 0.129.0+1.21.8" -ForegroundColor Yellow
    Write-Host "3. Ejecuta Minecraft con Fabric Loader 0.15.11" -ForegroundColor Yellow
    Write-Host "4. Para probar, usa F3+T para recargar recursos" -ForegroundColor Yellow
    
} else {
    Write-Host "`n=== ERROR EN CONSTRUCCIÓN ===" -ForegroundColor Red
    $buildResult | Select-String -Pattern "error|fail|exception" -Context 2 | ForEach-Object {
        Write-Host $_.Line -ForegroundColor Red
        Write-Host $_.Context.PreContext[0] -ForegroundColor DarkRed
        Write-Host $_.Context.PostContext[0] -ForegroundColor DarkRed
        Write-Host ""
    }
    
    Write-Host "`nPara más detalles ejecuta:" -ForegroundColor Yellow
    Write-Host ".\gradlew build --stacktrace" -ForegroundColor White
}