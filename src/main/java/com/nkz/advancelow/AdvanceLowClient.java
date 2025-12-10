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
                    client.getNetworkHandler().sendChatCommand("home casa");
                    Thread.sleep(6000);
                    client.getNetworkHandler().sendChatCommand("sit");
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
        
        for (Entity entity : player.getWorld().iterateEntities()) {
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