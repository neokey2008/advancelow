package com.nkz.advancelow.mixin;

import com.nkz.advancelow.AdvanceLowClient;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.Entity;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

@Mixin(MinecraftClient.class)
public class MinecraftClientMixin {
    
    @Inject(method = "doAttack", at = @At("HEAD"), cancellable = true)
    private void onAttack(CallbackInfoReturnable<Boolean> cir) {
        // Camuflaje: hacer que los ataques parezcan normales
        if (AdvanceLowClient.isReachEnabled()) {
            // Pequeñas variaciones para parecer humano
            try {
                Thread.sleep(5 + new java.util.Random().nextInt(15));
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }
    }
}