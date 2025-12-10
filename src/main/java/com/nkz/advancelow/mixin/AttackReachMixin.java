package com.nkz.advancelow.mixin;

import com.nkz.advancelow.AdvanceLowClient;
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
        if (AdvanceLowClient.isReachEnabled()) {
            try {
                long delay = 5 + (System.currentTimeMillis() % 20);
                Thread.sleep(delay);
            } catch (InterruptedException ignored) {}
        }
    }

    // ✔ Nuevo método correcto para MC 1.21.x — Attack reach
    @Inject(method = "getAttackRange", at = @At("HEAD"), cancellable = true)
    private void onGetAttackRange(CallbackInfoReturnable<Float> cir) {
        cir.setReturnValue((float) AdvanceLowClient.getCurrentReach());
    }

    // ✔ Nuevo método correcto para MC 1.21.x — Interaction reach
    @Inject(method = "getInteractionRange", at = @At("HEAD"), cancellable = true)
    private void onGetInteractionRange(CallbackInfoReturnable<Float> cir) {
        cir.setReturnValue((float) AdvanceLowClient.getCurrentReach());
    }
}
