package com.nkz.advancelow;

import net.fabricmc.api.ClientModInitializer;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientTickEvents;
import net.fabricmc.fabric.api.client.networking.v1.ClientPlayConnectionEvents;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.network.ClientPlayNetworkHandler;
import net.minecraft.client.network.PlayerListEntry;
import net.minecraft.entity.Entity;
import net.minecraft.entity.mob.HostileEntity;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.text.Text;
import net.minecraft.util.math.Box;
import net.minecraft.util.math.Vec3d;
import java.util.*;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

public class AdvanceLowClient implements ClientModInitializer {
    
    private static final Set<String> STAFF_RANKS = new HashSet<>(Arrays.asList(
        "MODERADOR", "MOD", "T-HELPER", "ADMIN", "OWNER", 
        "HELPER", "S-MANAGER", "STAFF", "MANAGER", "S-MOD",
        "T-MOD", "JR.MOD", "SR.MOD", "BUILDER", "DEV"
    ));
    
    private static boolean reachEnabled = true;
    private static boolean commandsExecuted = false;
    private static long lastAttackTime = 0;
    private static int tickCounter = 0;
    private static final Random random = new Random();
    private static final ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(2);
    
    // Configuración
    private static final double MAX_REACH = 4.5;
    private static final double VANILLA_REACH = 3.0;
    private static final float ATTACK_ANGLE = 180.0f;
    private static final int ATTACK_DELAY_MIN = 600;
    private static final int ATTACK_DELAY_MAX = 1200;
    
    @Override
    public void onInitializeClient() {
        System.out.println("[AdvanceLow] Inicializando mod educativo - Propiedad de NKZ");
        System.out.println("[AdvanceLow] Entorno controlado de investigación");
        
        // Registrar eventos
        ClientTickEvents.END_CLIENT_TICK.register(this::onClientTick);
        ClientPlayConnectionEvents.JOIN.register(this::onServerJoin);
        
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            scheduler.shutdown();
            System.out.println("[AdvanceLow] Mod detenido");
        }));
    }
    
    private void onServerJoin(ClientPlayNetworkHandler handler, MinecraftClient client) {
        // Resetear estado
        reachEnabled = true;
        commandsExecuted = false;
        lastAttackTime = 0;
        tickCounter = 0;
        
        System.out.println("[AdvanceLow] Conectado al servidor");
        
        // Detectar staff después de 5 segundos
        scheduler.schedule(() -> {
            if (client.player != null && client.world != null) {
                checkForStaff(client);
            }
        }, 5, TimeUnit.SECONDS);
    }
    
    private void onClientTick(MinecraftClient client) {
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
        if (client.getNetworkHandler() == null) return;
        
        for (PlayerListEntry entry : client.getNetworkHandler().getPlayerList()) {
            String displayName = entry.getDisplayName() != null ? 
                entry.getDisplayName().getString() : entry.getProfile().getName();
            
            String upperName = displayName.toUpperCase();
            for (String rank : STAFF_RANKS) {
                if (upperName.contains("[" + rank + "]") || 
                    upperName.contains(rank + "]") ||
                    upperName.contains(" " + rank + " ") ||
                    upperName.startsWith(rank + " ")) {
                    
                    System.out.println("[AdvanceLow] Staff detectado: " + displayName);
                    handleStaffDetection(client);
                    return;
                }
            }
        }
    }
    
    private void handleStaffDetection(MinecraftClient client) {
        if (commandsExecuted) return;
        
        reachEnabled = false;
        commandsExecuted = true;
        
        System.out.println("[AdvanceLow] ⚠️ STAFF DETECTADO - Desactivando funciones");
        
        // Ejecutar comandos en orden
        scheduler.schedule(() -> {
            if (client.player != null) {
                client.player.sendCommand("home casa");
                System.out.println("[AdvanceLow] Comando ejecutado: /home casa");
            }
        }, 0, TimeUnit.SECONDS);
        
        scheduler.schedule(() -> {
            if (client.player != null) {
                client.player.sendCommand("sit");
                System.out.println("[AdvanceLow] Comando ejecutado: /sit");
            }
        }, 6, TimeUnit.SECONDS);
    }
    
    private boolean shouldAttack() {
        long currentTime = System.currentTimeMillis();
        if (currentTime - lastAttackTime < getNextAttackDelay()) {
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
            
            // Rotación natural
            rotateToTarget(player, target);
            
            // Ataque con criticals sin saltar
            performCriticalAttack(player, target);
            
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
            if (entity instanceof HostileEntity && entity.isAlive() && !entity.isRemoved()) {
                double distance = playerPos.distanceTo(entity.getPos());
                double angle = calculateAngle(player, entity);
                
                if (distance <= MAX_REACH && Math.abs(angle) <= ATTACK_ANGLE / 2) {
                    targets.add(entity);
                }
            }
        }
        
        targets.sort(Comparator.comparingDouble(e -> playerPos.distanceTo(e.getPos())));
        return targets;
    }
    
    private double calculateAngle(PlayerEntity player, Entity target) {
        Vec3d lookVec = player.getRotationVec(1.0F);
        Vec3d targetVec = target.getPos().subtract(player.getPos()).normalize();
        return Math.toDegrees(Math.acos(lookVec.dotProduct(targetVec)));
    }
    
    private void rotateToTarget(PlayerEntity player, Entity target) {
        Vec3d targetPos = target.getPos().add(0, target.getHeight() / 2, 0);
        Vec3d playerPos = player.getEyePos();
        
        Vec3d diff = targetPos.subtract(playerPos);
        double distHorizontal = Math.sqrt(diff.x * diff.x + diff.z * diff.z);
        
        float yaw = (float) Math.toDegrees(Math.atan2(diff.z, diff.x)) - 90;
        float pitch = (float) -Math.toDegrees(Math.atan2(diff.y, distHorizontal));
        
        // Rotación suave (40% por tick)
        player.setYaw(player.getYaw() + clampAngle(yaw - player.getYaw()) * 0.4f);
        player.setPitch(player.getPitch() + clampAngle(pitch - player.getPitch()) * 0.4f);
    }
    
    private void performCriticalAttack(PlayerEntity player, Entity target) {
        // Critical sin saltar (método alternativo)
        if (player.isOnGround() && player.fallDistance > 0.0F) {
            player.attack(target);
            player.swingHand(player.getActiveHand());
        } else {
            // Simular critical con pequeño impulso
            player.setVelocity(player.getVelocity().x, 0.1, player.getVelocity().z);
            player.attack(target);
            player.swingHand(player.getActiveHand());
        }
    }
    
    private float clampAngle(float angle) {
        angle %= 360;
        if (angle > 180) angle -= 360;
        if (angle < -180) angle += 360;
        return angle;
    }
    
    private int getNextAttackDelay() {
        return ATTACK_DELAY_MIN + random.nextInt(ATTACK_DELAY_MAX - ATTACK_DELAY_MIN);
    }
    
    // Métodos para integración
    public static boolean isReachEnabled() {
        return reachEnabled;
    }
    
    public static double getCurrentReach() {
        return reachEnabled ? MAX_REACH : VANILLA_REACH;
    }
}