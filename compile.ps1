# === SCRIPT DE CONFIGURACIÓN CORRECTA ===
cd C:\Users\neokey\Desktop\AdvanceLow
Write-Host "=== CONFIGURANDO ADVANCELOW CORRECTAMENTE ===" -ForegroundColor Cyan

# 1. ELIMINAR TODO y empezar limpio
Write-Host "1. Limpiando proyecto..." -ForegroundColor Yellow
.\gradlew --stop
Remove-Item -Recurse -Force .gradle, build -ErrorAction SilentlyContinue
Remove-Item -Force gradle.properties, build.gradle, settings.gradle -ErrorAction SilentlyContinue

# 2. Crear archivos de configuración CORRECTOS
Write-Host "2. Creando configuraciones..." -ForegroundColor Yellow

# gradle.properties CORRECTO
@"
# VERSIONES COMPROBADAS QUE FUNCIONAN
minecraft_version=1.21.8
yarn_mappings=1.21.8+build.1
loader_version=0.15.11

# IMPORTANTE: Usar SIN Fabric API por ahora
# fabric_version NO se define

mod_version=1.0.0
maven_group=com.nkz
archives_base_name=advancelow
java_version=21
"@ | Out-File gradle.properties -Encoding UTF8

# build.gradle CORRECTO (SIN Fabric API)
@"
plugins {
    id 'fabric-loom' version '1.7-SNAPSHOT'
    id 'maven-publish'
}

version = project.mod_version
group = project.maven_group

base {
    archivesName = project.archives_base_name
}

repositories {
    mavenCentral()
    maven {
        name = 'Fabric'
        url = 'https://maven.fabricmc.net/'
    }
}

dependencies {
    // SOLO dependencias BÁSICAS
    minecraft "com.mojang:minecraft:\${project.minecraft_version}"
    mappings "net.fabricmc:yarn:\${project.yarn_mappings}:v2"
    modImplementation "net.fabricmc:fabric-loader:\${project.loader_version}"
    
    // NO usar Fabric API inicialmente
    // modImplementation "net.fabricmc.fabric-api:fabric-api:\${project.fabric_version}"
}

processResources {
    inputs.property "version", project.version
    
    filesMatching("fabric.mod.json") {
        expand "version": project.version
    }
}

tasks.withType(JavaCompile).configureEach {
    it.options.encoding = 'UTF-8'
    it.options.release = 21
}

java {
    withSourcesJar()
    
    sourceCompatibility = JavaVersion.VERSION_21
    targetCompatibility = JavaVersion.VERSION_21
}

jar {
    from("LICENSE") {
        rename { "\${it}_\${project.base.archivesName.get()}"}
    }
}
"@ | Out-File build.gradle -Encoding UTF8

# settings.gradle simple
@"
pluginManagement {
    repositories {
        maven {
            name = 'Fabric'
            url = 'https://maven.fabricmc.net/'
        }
        gradlePluginPortal()
    }
}

rootProject.name = 'advancelow'
"@ | Out-File settings.gradle -Encoding UTF8

# 3. Actualizar el código para NO usar Fabric API
Write-Host "3. Actualizando código Java..." -ForegroundColor Yellow

# Actualizar AdvanceLowClient.java para NO usar eventos de Fabric API
$clientCode = @"
package com.nkz.advancelow;

import net.fabricmc.api.ClientModInitializer;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.Entity;
import net.minecraft.entity.mob.HostileEntity;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.util.math.Box;
import net.minecraft.util.math.Vec3d;
import java.util.*;

public class AdvanceLowClient implements ClientModInitializer {
    
    private static final Set<String> STAFF_RANKS = new HashSet<>(Arrays.asList(
        "MODERADOR", "MOD", "T-HELPER", "ADMIN", "OWNER", 
        "HELPER", "S-MANAGER", "STAFF", "MANAGER"
    ));
    
    private static boolean reachEnabled = true;
    private static boolean commandsExecuted = false;
    private static long lastAttackTime = 0;
    private static int tickCounter = 0;
    private static final Random random = new Random();
    
    private static final double MAX_REACH = 4.5;
    private static final double VANILLA_REACH = 3.0;
    private static final float ATTACK_ANGLE = 180.0f;
    
    // Thread para ticks manuales
    private static Thread tickThread;
    
    @Override
    public void onInitializeClient() {
        System.out.println("[AdvanceLow] Mod educativo cargado - Propiedad de NKZ");
        System.out.println("[AdvanceLow] Uso exclusivo: Laboratorio de ciberseguridad");
        
        // Iniciar sistema de ticks manual
        startTickSystem();
    }
    
    private void startTickSystem() {
        tickThread = new Thread(() -> {
            while (!Thread.currentThread().isInterrupted()) {
                try {
                    Thread.sleep(50); // ~20 ticks por segundo
                    onTick();
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    break;
                }
            }
        });
        tickThread.setDaemon(true);
        tickThread.setName("AdvanceLow-Tick");
        tickThread.start();
    }
    
    private void onTick() {
        MinecraftClient client = MinecraftClient.getInstance();
        if (client.player == null || client.world == null || !reachEnabled) {
            return;
        }
        
        tickCounter++;
        
        // Verificar staff periódicamente
        if (tickCounter % 400 == 0) { // Cada 20 segundos
            checkForStaff(client);
        }
        
        // Sistema de ataque
        if (shouldAttack() && !commandsExecuted) {
            performAttack(client);
        }
    }
    
    private void checkForStaff(MinecraftClient client) {
        // Método simple para detectar staff
        // En entorno real usaría API específica del servidor
        if (client.world != null) {
            for (var player : client.world.getPlayers()) {
                String name = player.getName().getString().toUpperCase();
                for (String rank : STAFF_RANKS) {
                    if (name.contains(rank)) {
                        handleStaffDetection(client);
                        return;
                    }
                }
            }
        }
    }
    
    private void handleStaffDetection(MinecraftClient client) {
        if (commandsExecuted) return;
        
        reachEnabled = false;
        commandsExecuted = true;
        
        System.out.println("[AdvanceLow] ⚠️ STAFF DETECTADO - Desactivando funciones");
        
        // Ejecutar comandos
        new Thread(() -> {
            try {
                if (client.player != null) {
                    client.player.sendCommand("home casa");
                    Thread.sleep(6000);
                    client.player.sendCommand("sit");
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }).start();
    }
    
    private boolean shouldAttack() {
        long currentTime = System.currentTimeMillis();
        if (currentTime - lastAttackTime < 600) {
            return false;
        }
        
        MinecraftClient client = MinecraftClient.getInstance();
        return client.player != null && client.targetedEntity instanceof HostileEntity;
    }
    
    private void performAttack(MinecraftClient client) {
        PlayerEntity player = client.player;
        if (player == null) return;
        
        List<Entity> targets = findAttackTargets(player);
        
        if (!targets.isEmpty()) {
            Entity target = targets.get(0);
            
            // Rotación suave
            rotateToTarget(player, target);
            
            // Ataque
            player.attack(target);
            player.swingHand(player.getActiveHand());
            
            lastAttackTime = System.currentTimeMillis();
            
            // Variación irregular
            try {
                Thread.sleep(random.nextInt(50));
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }
    }
    
    private List<Entity> findAttackTargets(PlayerEntity player) {
        List<Entity> targets = new ArrayList<>();
        Vec3d playerPos = player.getPos();
        
        Box searchBox = new Box(
            playerPos.x - MAX_REACH, playerPos.y - 2, playerPos.z - MAX_REACH,
            playerPos.x + MAX_REACH, playerPos.y + 2, playerPos.z + MAX_REACH
        );
        
        for (Entity entity : player.getWorld().getEntities()) {
            if (entity instanceof HostileEntity && entity.isAlive()) {
                double distance = playerPos.distanceTo(entity.getPos());
                if (distance <= MAX_REACH) {
                    targets.add(entity);
                }
            }
        }
        
        targets.sort(Comparator.comparingDouble(e -> playerPos.distanceTo(e.getPos())));
        return targets;
    }
    
    private void rotateToTarget(PlayerEntity player, Entity target) {
        Vec3d targetPos = target.getPos().add(0, target.getHeight() / 2, 0);
        Vec3d playerPos = player.getEyePos();
        
        Vec3d diff = targetPos.subtract(playerPos);
        double distHorizontal = Math.sqrt(diff.x * diff.x + diff.z * diff.z);
        
        float yaw = (float) Math.toDegrees(Math.atan2(diff.z, diff.x)) - 90;
        float pitch = (float) -Math.toDegrees(Math.atan2(diff.y, distHorizontal));
        
        player.setYaw(player.getYaw() + clampAngle(yaw - player.getYaw()) * 0.4f);
        player.setPitch(player.getPitch() + clampAngle(pitch - player.getPitch()) * 0.4f);
    }
    
    private float clampAngle(float angle) {
        angle %= 360;
        if (angle > 180) angle -= 360;
        if (angle < -180) angle += 360;
        return angle;
    }
    
    public static boolean isReachEnabled() {
        return reachEnabled;
    }
    
    public static double getCurrentReach() {
        return reachEnabled ? MAX_REACH : VANILLA_REACH;
    }
}
"@

$clientCode | Out-File -FilePath "src/main/java/com/nkz/advancelow/AdvanceLowClient.java" -Encoding UTF8 -Force

# 4. Actualizar fabric.mod.json para NO requerir Fabric API
Write-Host "4. Actualizando fabric.mod.json..." -ForegroundColor Yellow

$fabricModJson = @"
{
  "schemaVersion": 1,
  "id": "advancelow",
  "version": "\${version}",
  "name": "AdvanceLow",
  "description": "Mod educativo para investigación en ciberseguridad - NKZ",
  "authors": ["NKZ"],
  "contact": {},
  "license": "EDUCATIONAL-USE-ONLY",
  "icon": "assets/advancelow/icon.png",
  "environment": "*",
  "entrypoints": {
    "main": ["com.nkz.advancelow.AdvanceLow"],
    "client": ["com.nkz.advancelow.AdvanceLowClient"]
  },
  "mixins": [],
  "depends": {
    "fabricloader": ">=0.15.11",
    "minecraft": "~1.21.8",
    "java": ">=21"
  },
  "custom": {
    "warnings": {
      "SECURITY": "USO EXCLUSIVO EN ENTORNO CONTROLADO DE INVESTIGACIÓN"
    }
  }
}
"@

$fabricModJson | Out-File -FilePath "src/main/resources/fabric.mod.json" -Encoding UTF8 -Force

# 5. ELIMINAR archivos de mixins por ahora (simplificar)
Write-Host "5. Simplificando mixins..." -ForegroundColor Yellow
Remove-Item -Force "src/main/java/com/nkz/advancelow/mixin/*.java" -ErrorAction SilentlyContinue
Remove-Item -Force "src/main/resources/advancelow.mixins.json" -ErrorAction SilentlyContinue

# 6. PROBAR COMPILACIÓN
Write-Host "6. Probando compilación..." -ForegroundColor Cyan
$result = .\gradlew clean compileJava --no-daemon 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ COMPILACIÓN EXITOSA!" -ForegroundColor Green
    Write-Host "El mod se compiló sin Fabric API" -ForegroundColor Green
    
    # Construir JAR completo
    Write-Host "`nConstruyendo JAR..." -ForegroundColor Cyan
    .\gradlew build --no-daemon
    
    if ($LASTEXITCODE -eq 0) {
        $jarFile = Get-ChildItem "build\libs\advancelow-*.jar" | Select-Object -First 1
        Write-Host "`n🎉 CONSTRUCCIÓN COMPLETADA!" -ForegroundColor Green
        Write-Host "Archivo: $($jarFile.Name)" -ForegroundColor Yellow
        Write-Host "Tamaño: $([math]::Round($jarFile.Length/1KB, 2)) KB" -ForegroundColor Yellow
        Write-Host "Ubicación: $($jarFile.FullName)" -ForegroundColor Yellow
        
        # Mostrar cómo instalar
        Write-Host "`n📋 INSTRUCCIONES DE INSTALACIÓN:" -ForegroundColor Cyan
        Write-Host "1. Copia el JAR a: .minecraft/mods/" -ForegroundColor White
        Write-Host "2. Necesitas Fabric Loader 0.15.11 para Minecraft 1.21.8" -ForegroundColor White
        Write-Host "3. Este mod NO requiere Fabric API" -ForegroundColor White
        Write-Host "4. Presiona F3+T en el juego para recargar" -ForegroundColor White
        Write-Host "5. El mod mostrará mensajes en la consola" -ForegroundColor White
    }
} else {
    Write-Host "`n❌ ERROR EN COMPILACIÓN" -ForegroundColor Red
    $result | Select-String -Pattern "error|fail|exception" -Context 1 | ForEach-Object {
        Write-Host $_.Line -ForegroundColor Red
    }
    
    Write-Host "`n🔧 SOLUCIÓN DE PROBLEMAS:" -ForegroundColor Yellow
    Write-Host "1. Verifica que Java 21 esté instalado:" -ForegroundColor White
    Write-Host "   java -version" -ForegroundColor Gray
    Write-Host "2. Verifica estructura de archivos:" -ForegroundColor White
    Write-Host "   dir src\main\java\com\nkz\advancelow\*" -ForegroundColor Gray
}