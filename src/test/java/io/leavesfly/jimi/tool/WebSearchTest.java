package io.leavesfly.jimi.tool;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.leavesfly.jimi.config.ConfigLoader;
import io.leavesfly.jimi.tool.web.WebSearch;
import lombok.extern.slf4j.Slf4j;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import reactor.core.publisher.Mono;

import java.util.HashMap;
import java.util.Map;

/**
 * WebSearch 工具测试
 */
@Slf4j
public class WebSearchTest {
    
    private WebSearch webSearch;
    private ConfigLoader configLoader;
    private ObjectMapper objectMapper;
    
    @BeforeEach
    public void setUp() {
        objectMapper = new ObjectMapper();
        configLoader = new ConfigLoader(objectMapper);
        
        // 使用 ConfigLoader 创建 WebSearch 实例
        webSearch = new WebSearch(configLoader, objectMapper);
    }
    
    @Test
    public void testBasicSearch() {
        log.info("=== 测试基本搜索功能 ===");
        
        WebSearch.Params params = WebSearch.Params.builder()
            .query("Java Spring Boot 最新特性")
            .limit(3)
            .includeContent(false)
            .build();
        
        Mono<ToolResult> resultMono = webSearch.execute(params);
        ToolResult result = resultMono.block();
        
        log.info("搜索结果:");
        log.info(result.getOutput());
        log.info("是否成功: {}", result.isOk());
    }
    
    @Test
    public void testSearchWithContent() {
        log.info("=== 测试包含网页内容的搜索 ===");
        
        WebSearch.Params params = WebSearch.Params.builder()
            .query("OpenAI GPT-4")
            .limit(2)
            .includeContent(true)
            .build();
        
        Mono<ToolResult> resultMono = webSearch.execute(params);
        ToolResult result = resultMono.block();
        
        log.info("搜索结果（包含内容）:");
        log.info(result.getOutput());
        log.info("是否成功: {}", result.isOk());
    }
    
    @Test
    public void testSearchWithEmptyQuery() {
        log.info("=== 测试空查询参数 ===");
        
        WebSearch.Params params = WebSearch.Params.builder()
            .query("")
            .limit(5)
            .build();
        
        Mono<ToolResult> resultMono = webSearch.execute(params);
        ToolResult result = resultMono.block();
        
        log.info("空查询结果:");
        log.info("是否成功: {}", result.isOk());
        log.info("错误信息: {}", result.getMessage());
    }
    
    @Test
    public void testSearchWithInvalidLimit() {
        log.info("=== 测试无效的limit参数 ===");
        
        WebSearch.Params params = WebSearch.Params.builder()
            .query("测试查询")
            .limit(100)  // 超出范围
            .build();
        
        Mono<ToolResult> resultMono = webSearch.execute(params);
        ToolResult result = resultMono.block();
        
        log.info("无效limit结果:");
        log.info("是否成功: {}", result.isOk());
        log.info("错误信息: {}", result.getMessage());
    }
    
    @Test
    public void testSearchWithCustomHeaders() {
        log.info("=== 测试自定义Header ===");
        
        // 使用默认配置，不需要自定义 Header
        WebSearch.Params params = WebSearch.Params.builder()
            .query("人工智能")
            .limit(3)
            .build();
        
        Mono<ToolResult> resultMono = webSearch.execute(params);
        ToolResult result = resultMono.block();
        
        log.info("搜索结果:");
        log.info(result.getOutput());
        log.info("是否成功: {}", result.isOk());
    }
    
    @Test
    public void testDefaultConstructor() {
        log.info("=== 测试默认构造函数（使用配置文件） ===");
        
        // 使用 ConfigLoader 创建
        WebSearch defaultWebSearch = new WebSearch(configLoader, objectMapper);
        
        WebSearch.Params params = WebSearch.Params.builder()
            .query("AI Agent")
            .limit(3)
            .build();
        
        Mono<ToolResult> resultMono = defaultWebSearch.execute(params);
        ToolResult result = resultMono.block();
        
        log.info("默认配置搜索结果:");
        log.info(result.getOutput());
        log.info("是否成功: {}", result.isOk());
    }
}
