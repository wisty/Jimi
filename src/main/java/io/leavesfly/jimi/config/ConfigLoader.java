package io.leavesfly.jimi.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.leavesfly.jimi.exception.ConfigException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;

/**
 * 配置加载服务
 * 负责从配置文件加载、保存和管理 Jimi 配置
 */
@Slf4j
@Service
public class ConfigLoader {

    private static final String CONFIG_FILE_NAME = "config.json";
    private static final String KIMI_CLI_DIR = ".jimi";

    private final ObjectMapper objectMapper;

    public ConfigLoader(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    /**
     * 获取配置文件路径
     */
    public Path getConfigFilePath() {
        String userHome = System.getProperty("user.home");
        return Paths.get(userHome, KIMI_CLI_DIR, CONFIG_FILE_NAME);
    }

    /**
     * 加载配置
     * 配置优先级：自定义配置文件 > 默认配置文件 > 内置默认配置
     */
    public JimiConfig loadConfig(Path customConfigFile) {
        Path configFile = customConfigFile != null ? customConfigFile : getConfigFilePath();

        JimiConfig config;
        if (Files.exists(configFile)) {
            log.debug("Loading config from file: {}", configFile);
            try {
                config = objectMapper.readValue(configFile.toFile(), JimiConfig.class);
            } catch (IOException e) {
                throw new ConfigException("Failed to load config from file: " + configFile, e);
            }
        } else {
            log.debug("No config file found, creating default config");
            config = getDefaultConfig();
            try {
                saveConfig(config, configFile);
            } catch (ConfigException e) {
                log.warn("Failed to save default config: {}", e.getMessage());
            }
        }

        // 验证配置
        try {
            config.validate();
        } catch (IllegalStateException e) {
            throw new ConfigException("Invalid configuration: " + e.getMessage(), e);
        }

        return config;
    }

    /**
     * 保存配置
     */
    public void saveConfig(JimiConfig config, Path configFile) {
        try {
            // 确保目录存在
            Files.createDirectories(configFile.getParent());

            // 写入配置文件
            objectMapper.writerWithDefaultPrettyPrinter()
                    .writeValue(configFile.toFile(), config);

            log.info("Config saved to: {}", configFile);
        } catch (IOException e) {
            throw new ConfigException("Failed to save config to file: " + configFile, e);
        }
    }

    /**
     * 获取默认内置配置
     */
    public JimiConfig getDefaultConfig() {
        try {
            var resource = getClass().getClassLoader().getResourceAsStream(CONFIG_FILE_NAME);
            if (resource != null) {
                log.debug("Loading default config from classpath: {}", CONFIG_FILE_NAME);
                return objectMapper.readValue(resource, JimiConfig.class);
            }
        } catch (IOException e) {
            log.warn("Failed to load default config from classpath: {}", e.getMessage());
        }

        // 如果类路径中没有配置文件，返回硬编码的默认配置
        log.debug("Using hardcoded default config");
        return createHardcodedDefaultConfig();
    }

    /**
     * 创建硬编码的默认配置
     */
    private JimiConfig createHardcodedDefaultConfig() {
        // 创建 Qwen 提供商配置
        LLMProviderConfig qwenProvider = LLMProviderConfig.builder()
                .type(LLMProviderConfig.ProviderType.QWEN)
                .baseUrl("https://dashscope.aliyuncs.com/compatible-mode/v1")
                .apiKey("")
                .build();

        // 创建 Ollama 提供商配置
        LLMProviderConfig ollamaProvider = LLMProviderConfig.builder()
                .type(LLMProviderConfig.ProviderType.OLLAMA)
                .baseUrl("http://localhost:11434")
                .apiKey("")
                .build();

        // 创建 Qwen 模型配置
        LLMModelConfig qwenModel = LLMModelConfig.builder()
                .provider("qwen")
                .model("qwen-max")
                .maxContextSize(32000)
                .build();

        // 创建 Ollama 模型配置
        LLMModelConfig ollamaModel = LLMModelConfig.builder()
                .provider("ollama")
                .model("qwen2.5-coder:32b")
                .maxContextSize(32768)
                .build();

        // 创建循环控制配置
        LoopControlConfig loopControl = LoopControlConfig.builder()
                .maxStepsPerRun(10)
                .maxRetriesPerStep(3)
                .build();

        // 构建完整配置
        Map<String, LLMProviderConfig> providers = new HashMap<>();
        providers.put("qwen", qwenProvider);
        providers.put("ollama", ollamaProvider);

        Map<String, LLMModelConfig> models = new HashMap<>();
        models.put("qwen-max", qwenModel);
        models.put("qwen2.5-coder:32b", ollamaModel);

        return JimiConfig.builder()
                .defaultModel("qwen-max")
                .providers(providers)
                .models(models)
                .loopControl(loopControl)
                .build();
    }

}
