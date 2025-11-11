package io.leavesfly.jimi.soul.toolcall;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.leavesfly.jimi.engine.toolcall.ArgumentsNormalizer;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * ArgumentsNormalizer 测试类
 */
class ArgumentsNormalizerTest {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void testEscapeUnescapedQuotesInXmlContent() {
        // 模拟真实场景: content 字段中包含未转义的双引号
        // 构造一个包含未转义引号的JSON字符串
        String xmlPart = "<?xml version=" + "\"1.0\" encoding=" + "\"UTF-8\"" + "?>";
        String input = "{\"path\": \"/test/pom.xml\", \"content\": \"" + xmlPart + "\", \"mode\": \"overwrite\"}";
        
        System.out.println("\n=== Test Unescaped Quotes in XML ===");
        System.out.println("Input: " + input);
        
        String result = ArgumentsNormalizer.normalizeToValidJson(input, objectMapper);
        System.out.println("Result: " + result);
        
        // 验证结果可以被解析为有效的 JSON
        assertDoesNotThrow(() -> {
            var tree = objectMapper.readTree(result);
            System.out.println("Parsed successfully: " + tree.toPrettyString());
        });
    }

    @Test
    void testComplexXmlContent() {
        // 更复杂的 XML 内容测试
        String input = "{\"content\": \"<dependency>\\n    <groupId>org.springframework.boot</groupId>\\n</dependency>\"}";
        
        String result = ArgumentsNormalizer.normalizeToValidJson(input, objectMapper);
        
        System.out.println("Complex XML Input: " + input);
        System.out.println("Complex XML Result: " + result);
        
        assertDoesNotThrow(() -> objectMapper.readTree(result));
    }

    @Test
    void testNormalJsonShouldNotBeAffected() {
        // 正常的 JSON 不应该被影响
        String input = "{\"name\": \"test\", \"value\": 123}";
        
        String result = ArgumentsNormalizer.normalizeToValidJson(input, objectMapper);
        
        assertEquals(input, result);
        assertDoesNotThrow(() -> objectMapper.readTree(result));
    }

    @Test
    void testJsonWithEscapedQuotes() {
        // 已经正确转义的 JSON 不应该被重复转义
        String input = "{\"message\": \"This is a \\\"quoted\\\" text\"}";
        
        String result = ArgumentsNormalizer.normalizeToValidJson(input, objectMapper);
        
        System.out.println("Escaped Input: " + input);
        System.out.println("Escaped Result: " + result);
        
        assertDoesNotThrow(() -> objectMapper.readTree(result));
    }

    @Test
    void testMarkdownContentWithQuotes() {
        // 模拟 Markdown 文档内容，包含大量未转义的引号
        String markdownContent = "# Title\n" +
                "- **属性**: \"x," + "\"y\"" + ": 坐标\n" +
                "- direction: \"UP, DOWN\"";
        
        String input = "{\"path\": \"/test/doc.md\", \"content\": \"" + markdownContent + "\", \"mode\": \"overwrite\"}";
        
        System.out.println("\n=== Test Markdown Content ===");
        System.out.println("Input: " + input);
        
        String result = ArgumentsNormalizer.normalizeToValidJson(input, objectMapper);
        System.out.println("Result: " + result);
        
        // 验证结果可以被解析为有效的 JSON
        assertDoesNotThrow(() -> {
            var tree = objectMapper.readTree(result);
            System.out.println("Parsed successfully!");
            System.out.println("Content field: " + tree.get("content").asText());
        });
    }

    @Test
    void testComplexMarkdownWithMultipleQuotes() {
        // 更复杂的场景：包含多个未转义引号的 Markdown
        String complexMd = "## Section\n" +
                "- Item with " + "\"quotes\" " + "here\n" +
                "Code: { " + "\"key\": \"value\" " + "}";
        
        String input = "{\"content\": \"" + complexMd + "\"}";
        
        System.out.println("\n=== Test Complex Markdown ===");
        System.out.println("Input: " + input);
        
        String result = ArgumentsNormalizer.normalizeToValidJson(input, objectMapper);
        System.out.println("Result: " + result);
        
        assertDoesNotThrow(() -> objectMapper.readTree(result));
    }
}
