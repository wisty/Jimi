package io.leavesfly.jimi.config;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.HashMap;
import java.util.Map;

/**
 * Web 搜索配置
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WebSearchConfig {
    
    /**
     * 搜索服务基础URL
     */
    @JsonProperty("base_url")
    @Builder.Default
    private String baseUrl = "";
    
    /**
     * API密钥
     */
    @JsonProperty("api_key")
    @Builder.Default
    private String apiKey = "";
    
    /**
     * 自定义HTTP头
     */
    @JsonProperty("custom_headers")
    @Builder.Default
    private Map<String, String> customHeaders = new HashMap<>();
    
    /**
     * 检查配置是否已设置
     */
    public boolean isConfigured() {
        return baseUrl != null && !baseUrl.isEmpty() 
            && apiKey != null && !apiKey.isEmpty();
    }
}
