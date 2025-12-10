# Script para compilar AdvanceLow
Write-Host "=== COMPILANDO ADVANCELOW ===" -ForegroundColor Cyan

cd C:\Users\neokey\Desktop\AdvanceLow

# 1. Detener todos los daemons de Gradle
Write-Host "`n1. Deteniendo Gradle daemons..." -ForegroundColor Yellow
.\gradlew --stop
Start-Sleep -Seconds 2

# 2. Limpiar completamente el proyecto
Write-Host "`n2. Limpiando archivos temporales..." -ForegroundColor Yellow
Remove-Item -Recurse -Force .gradle -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .idea -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force bin -ErrorAction SilentlyContinue
Remove-Item -Force .classpath, .project -ErrorAction SilentlyContinue
Write-Host "   [OK] Limpieza completada" -ForegroundColor Green

# 3. Verificar Java 21
Write-Host "`n3. Verificando Java..." -ForegroundColor Yellow
$javaVersion = java -version 2>&1 | Select-String "version"
Write-Host "   Java detectado: $javaVersion" -ForegroundColor Gray

if ($javaVersion -notmatch "21") {
    Write-Host "   [ADVERTENCIA] Se requiere Java 21" -ForegroundColor Red
    Write-Host "   Descarga desde: https://adoptium.net/" -ForegroundColor Yellow
}

# 4. Actualizar wrapper de Gradle
Write-Host "`n4. Actualizando Gradle Wrapper..." -ForegroundColor Yellow
.\gradlew wrapper --gradle-version=8.10.2 --no-daemon

# 5. Intentar compilacion
Write-Host "`n5. Descargando dependencias y compilando..." -ForegroundColor Cyan
Write-Host "   (Esto puede tardar varios minutos la primera vez)" -ForegroundColor Gray

$output = .\gradlew clean build --no-daemon --refresh-dependencies 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[EXITO] Compilacion exitosa!" -ForegroundColor Green
    
    # Mostrar informacion del JAR generado
    $jarFile = Get-ChildItem "build\libs\*.jar" -Exclude "*-sources.jar" | Select-Object -First 1
    
    if ($jarFile) {
        Write-Host "`n[MOD GENERADO]" -ForegroundColor Cyan
        Write-Host "   Archivo: $($jarFile.Name)" -ForegroundColor White
        Write-Host "   Tamano: $([math]::Round($jarFile.Length/1KB, 2)) KB" -ForegroundColor White
        Write-Host "   Ubicacion: $($jarFile.FullName)" -ForegroundColor White
        
        Write-Host "`n[INSTALACION]" -ForegroundColor Cyan
        Write-Host "   1. Copia el JAR a tu carpeta .minecraft/mods/" -ForegroundColor White
        Write-Host "   2. Asegurate de tener Fabric Loader 0.15.11 instalado" -ForegroundColor White
        Write-Host "   3. Lanza Minecraft 1.21.8 con Fabric" -ForegroundColor White
    }
    
    # Generar sources para el IDE
    Write-Host "`n6. Generando archivos para el IDE..." -ForegroundColor Yellow
    .\gradlew genSources --no-daemon
    
    Write-Host "`n[PROYECTO LISTO]" -ForegroundColor Green
    Write-Host "`n[SIGUIENTE PASO]" -ForegroundColor Cyan
    Write-Host "   - Si usas VS Code: Recarga la ventana (Ctrl+Shift+P > Reload Window)" -ForegroundColor White
    Write-Host "   - Si usas IntelliJ: File > Invalidate Caches / Restart" -ForegroundColor White
    
} else {
    Write-Host "`n[ERROR] Error en la compilacion" -ForegroundColor Red
    Write-Host "`nDetalles del error:" -ForegroundColor Yellow
    $output | Select-String -Pattern "FAILURE|error|Error|ERROR" -Context 2 | ForEach-Object {
        Write-Host $_.Line -ForegroundColor Red
    }
    
    Write-Host "`n[POSIBLES SOLUCIONES]" -ForegroundColor Yellow
    Write-Host "   1. Verifica que Java 21 este instalado y sea la version por defecto" -ForegroundColor White
    Write-Host "   2. Verifica tu conexion a internet (se descargan muchas dependencias)" -ForegroundColor White
    Write-Host "   3. Ejecuta: .\gradlew clean build --stacktrace" -ForegroundColor White
    Write-Host "   4. Revisa el log completo en: build/gradle.log" -ForegroundColor White
    
    # Guardar log completo
    $output | Out-File -FilePath "build-error.log" -Encoding UTF8
    Write-Host "`n   Log guardado en: build-error.log" -ForegroundColor Gray
}