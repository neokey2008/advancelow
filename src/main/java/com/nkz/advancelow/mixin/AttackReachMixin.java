package com.nkz.advancelow.mixin;

import com.nkz.advancelow.AdvanceLowClient;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.network.ClientPlayerInteractionManager;
import net.minecraft.entity.Entity;
import net.minecraft.entity.player.PlayerEntity;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

@Mixin(ClientPlayerInteractionManager.class)
public class AttackReachMixin {
    
    @Inject(method = "attackEntity", at = @At("HEAD"), cancellable = true)
    private void onAttackEntity(PlayerEntity player, Entity target, CallbackInfo ci) {
        // Camuflaje: pequeño delay aleatorio
        if (AdvanceLowClient.isReachEnabled()) {
            try {
                long delay = 5 + (System.currentTimeMillis() % 20);
                Thread.sleep(delay);
            } catch (InterruptedException ignored) {}
        }
    }
    
    @Inject(method = "getReachDistance", at = @At("HEAD"), cancellable = true)
    private void onGetReachDistance(CallbackInfoReturnable<Float> cir) {
        float reach = (float) AdvanceLowClient.getCurrentReach();
        cir.setReturnValue(reach);
    }
}