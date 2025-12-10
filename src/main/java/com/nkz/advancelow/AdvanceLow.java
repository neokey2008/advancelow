package com.nkz.advancelow;

import net.fabricmc.api.ModInitializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class AdvanceLow implements ModInitializer {
    public static final String MOD_ID = "advancelow";
    public static final Logger LOGGER = LoggerFactory.getLogger(MOD_ID);
    
    @Override
    public void onInitialize() {
        LOGGER.info("=== ADVANCELOW INICIALIZADO ===");
        LOGGER.info("Propiedad: NKZ - Mod educativo");
        LOGGER.info("Uso exclusivo: Laboratorio de ciberseguridad");
        LOGGER.info("Versión: 1.0.0");
        LOGGER.info("================================");
    }
}