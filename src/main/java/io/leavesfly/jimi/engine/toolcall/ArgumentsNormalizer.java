package io.leavesfly.jimi.engine.toolcall;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;

import java.util.ArrayList;
import java.util.List;


/**
 * 工具调用参数标准化器
 * <p>
 * 职责：
 * - 标准化工具调用参数格式
 * - 处理双重转义的JSON
 * - 转换逗号分隔的参数为JSON格式
 * - 修复常见的参数格式问题
 * - 提供通用容错函数处理各种异常格式
 */
@Slf4j
public class ArgumentsNormalizer {


    /**
     * 通用容错函数：将 LLM 工具调用中的 arguments 参数转换为标准 JSON 格式
     * <p>
     * 标准化流程：
     * 0. 校验 arguments 是否已经是合法的 JSON，如果是则直接返回
     * 1. 移除前后多余的 null
     * 2. 处理双重转义
     * 3. 修复字符串值中未转义的引号
     * 4. 修复缺失的引号
     * 5. 修复不匹配的括号
     * 6. 修复非法转义字符
     * 7. 处理逗号分隔的参数
     *
     * @param arguments    原始参数字符串
     * @param objectMapper Jackson ObjectMapper 实例
     * @return 标准化后的 JSON 字符串
     * //     * @throws ArgumentsNormalizationException 当无法修复参数格式时抛出
     */
    public static String normalizeToValidJson(String arguments, ObjectMapper objectMapper) {

        if (arguments == null || arguments.trim().isEmpty()) {
            return "{}";
        }

        String normalized = arguments.trim();

        // 步骤 0: 先校验是否已经是合法的 JSON，是的话直接返回
        if (isStrictValidJson(normalized, objectMapper)) {
            return normalized;
        }

        // 步骤 1: 移除前后多余的 null
        normalized = removeNullPrefix(normalized);
        normalized = removeNullSuffix(normalized);

        // 步骤 2: 处理双重转义
        normalized = unescapeDoubleEscapedJsonSafe(normalized);

        // 步骤 3: 修复字符串值中未转义的引号(必须在修复缺失引号之前)
        normalized = escapeUnescapedQuotesInValues(normalized);

        // 步骤 4: 修复缺失的引号
        normalized = fixMissingQuotes(normalized);

        // 步骤 5: 修复不匹配的括号
        normalized = fixUnbalancedBrackets(normalized);

        // 步骤 6: 修复非法转义字符
        normalized = fixIllegalEscapes(normalized);

        // 步骤 7: 处理逗号分隔的参数
        normalized = convertCommaDelimitedToJsonSafe(normalized);

        return normalized;

    }

    /**
     * 严格校验是否为合法的 JSON 字符串
     * 注意：Jackson 的 objectMapper.readTree() 只会解析第一个 JSON 结构，
     * 对于 "{...}null" 这样的字符串也会返回成功，因为它成功解析了前面的 {}。
     * 这个方法会确保整个字符串都是合法的 JSON，不允许有多余的后缀。
     *
     * @param json         待校验的字符串
     * @param objectMapper Jackson ObjectMapper 实例
     * @return 是否为严格的合法 JSON
     */
    private static boolean isStrictValidJson(String json, ObjectMapper objectMapper) {
        try {
            JsonParser parser = objectMapper.getFactory().createParser(json);
            objectMapper.readTree(parser);
            
            // 检查是否还有多余的内容（如后缀 null）
            // 如果能继续读取到 token，说明有多余内容
            if (parser.nextToken() != null) {
                log.debug("JSON has extra content after main structure: {}", json);
                return false;
            }
            
            // 整个字符串都是合法的 JSON
            return true;
        } catch (Exception e) {
            // 不是合法的 JSON，继续执行标准化流程
            log.debug("Arguments is not valid JSON, proceeding with normalization: {}", e.getMessage());
            return false;
        }
    }


    /**
     * 移除开头的 null（循环处理多个连续的null）
     */
    private static String removeNullPrefix(String input) {
        String trimmed = input.trim();
        String original = trimmed;
        boolean removed = false;
        
        while (trimmed.startsWith("null")) {
            String afterNull = trimmed.substring(4).trim();
            // 验证后面是否为有效的JSON结构
            if (afterNull.startsWith("{") || afterNull.startsWith("[") || 
                    (afterNull.startsWith("\"") && afterNull.length() > 2)) {
                trimmed = afterNull;
                removed = true;
            } else {
                break;
            }
        }
        
        if (removed) {
            log.warn("Removed 'null' prefix from arguments: {} -> {}", original, trimmed);
        }
        return trimmed;
    }

    /**
     * 移除末尾的 null（循环处理多个连续的null）
     */
    private static String removeNullSuffix(String input) {
        String trimmed = input.trim();
        String original = trimmed;
        boolean removed = false;
        
        while (trimmed.endsWith("null")) {
            String beforeNull = trimmed.substring(0, trimmed.length() - 4).trim();
            // 验证前面是否为完整的JSON结构
            if ((beforeNull.startsWith("{") && beforeNull.endsWith("}")) ||
                    (beforeNull.startsWith("[") && beforeNull.endsWith("]")) ||
                    (beforeNull.startsWith("\"") && beforeNull.endsWith("\"") && beforeNull.length() > 2)) {
                trimmed = beforeNull;
                removed = true;
            } else {
                break;
            }
        }
        
        if (removed) {
            log.warn("Removed 'null' suffix from arguments: {} -> {}", original, trimmed);
        }
        return trimmed;
    }

    /**
     * 安全的双重转义处理
     */
    private static String unescapeDoubleEscapedJsonSafe(String input) {
        // 处理整体被双引号包裹的双重转义 JSON
        if (input.startsWith("\"") && input.endsWith("\"") && input.length() > 2) {
            try {
                String unescaped = input.substring(1, input.length() - 1)
                        .replace("\\\"", "\"")
                        .replace("\\\\", "\\");

                // 验证是否为有效的 JSON 结构
                if ((unescaped.startsWith("{") && unescaped.endsWith("}")) ||
                        (unescaped.startsWith("[") && unescaped.endsWith("]"))) {
                    log.warn("Unescaped double-escaped JSON: {}", input);
                    return unescaped;
                }
            } catch (Exception e) {
                log.debug("Failed to unescape double-escaped JSON, using as-is", e);
            }
        }

        // 处理包含转义引号但不是整体包裹的情况
        if (input.contains("\\\"") && !input.startsWith("\"")) {
            String unescaped = input.replace("\\\"", "\"");
            if ((unescaped.startsWith("{") && unescaped.endsWith("}")) ||
                    (unescaped.startsWith("[") && unescaped.endsWith("]"))) {
                log.warn("Unescaped quotes in JSON: {}", input);
                return unescaped;
            }
        }

        return input;
    }

    /**
     * 修复字符串值中未转义的引号和特殊字符
     * 处理场景: {"content": "text with "unescaped" quotes and\nnewlines"}
     * 这种情况通常出现在 content 字段包含 XML、HTML、Markdown 等文本时
     */
    private static String escapeUnescapedQuotesInValues(String input) {
        // 只处理对象和数组格式
        if ((!input.startsWith("{") || !input.endsWith("}")) &&
                (!input.startsWith("[") || !input.endsWith("]"))) {
            return input;
        }

        try {
            StringBuilder result = new StringBuilder();
            boolean inString = false;
            boolean afterColon = false;  // 标记是否在冒号之后(值位置)
            int braceDepth = 0;  // 花括号深度
            int bracketDepth = 0;  // 方括号深度

            for (int i = 0; i < input.length(); i++) {
                char c = input.charAt(i);
                char prev = i > 0 ? input.charAt(i - 1) : '\0';

                // 检测是否是转义字符
                boolean isEscaped = (prev == '\\');

                // 处理引号
                if (c == '"' && !isEscaped) {
                    if (!inString) {
                        // 开始字符串
                        inString = true;
                        result.append(c);
                    } else {
                        // 可能是字符串结束,也可能是值内部未转义的引号
                        // 检查后续字符来判断
                        int nextNonSpace = findNextNonSpaceChar(input, i + 1);

                        if (afterColon && nextNonSpace != -1) {
                            char nextChar = input.charAt(nextNonSpace);
                            // 如果后面不是逗号、右括号、右花括号,说明是值内部的引号需要转义
                            if (nextChar != ',' && nextChar != '}' && nextChar != ']') {
                                result.append("\\\"");  // 转义引号
                                continue;
                            }
                        }

                        // 正常的字符串结束
                        inString = false;
                        afterColon = false;
                        result.append(c);
                    }
                } else if (!inString) {
                    // JSON 结构字符
                    if (c == ':') {
                        afterColon = true;
                    } else if (c == ',' || c == '{' || c == '[') {
                        afterColon = false;
                    }

                    if (c == '{') braceDepth++;
                    else if (c == '}') braceDepth--;
                    else if (c == '[') bracketDepth++;
                    else if (c == ']') bracketDepth--;

                    result.append(c);
                } else {
                    // 字符串内部的字符 - 需要转义特殊字符
                    if (!isEscaped && afterColon) {
                        switch (c) {
                            case '\n':
                                result.append("\\n");
                                break;
                            case '\r':
                                result.append("\\r");
                                break;
                            case '\t':
                                result.append("\\t");
                                break;
                            case '\\':
                                result.append("\\\\");
                                break;
                            default:
                                result.append(c);
                        }
                    } else {
                        result.append(c);
                    }
                }
            }

            String resultStr = result.toString();
            if (!resultStr.equals(input)) {
                log.warn("Escaped unescaped quotes and special chars in JSON values. Original length: {}, Fixed length: {}",
                        input.length(), resultStr.length());
                return resultStr;
            }
        } catch (Exception e) {
            log.debug("Failed to escape unescaped quotes, using as-is", e);
        }

        return input;
    }

    /**
     * 查找下一个非空格字符的位置
     */
    private static int findNextNonSpaceChar(String str, int startIndex) {
        for (int i = startIndex; i < str.length(); i++) {
            char c = str.charAt(i);
            if (c != ' ' && c != '\t' && c != '\n' && c != '\r') {
                return i;
            }
        }
        return -1;
    }

    /**
     * 修复缺失的引号
     * 例如: {key: value} -> {"key": "value"}
     */
    private static String fixMissingQuotes(String input) {
        // 只处理对象格式
        if (!input.startsWith("{") || !input.endsWith("}")) {
            return input;
        }

        try {
            // 尝试使用正则表达式修复常见的缺失引号问题
            String fixed = input
                    // 修复键没有引号的情况: {key: -> {"key":
                    .replaceAll("\\{\\s*([a-zA-Z_][a-zA-Z0-9_]*)\\s*:", "{\"$1\":")
                    .replaceAll(",\\s*([a-zA-Z_][a-zA-Z0-9_]*)\\s*:", ",\"$1\":");

            if (!fixed.equals(input)) {
                log.warn("Fixed missing quotes in JSON keys: {} -> {}", input, fixed);
                return fixed;
            }
        } catch (Exception e) {
            log.debug("Failed to fix missing quotes, using as-is", e);
        }

        return input;
    }

    /**
     * 修复不匹配的括号
     */
    private static String fixUnbalancedBrackets(String input) {
        int openCurly = 0, closeCurly = 0;
        int openSquare = 0, closeSquare = 0;
        boolean inString = false;
        char stringChar = '\0';

        for (int i = 0; i < input.length(); i++) {
            char c = input.charAt(i);

            // 处理字符串内部
            if ((c == '"' || c == '\'') && (i == 0 || input.charAt(i - 1) != '\\')) {
                if (!inString) {
                    inString = true;
                    stringChar = c;
                } else if (c == stringChar) {
                    inString = false;
                }
                continue;
            }

            if (inString) continue;

            // 统计括号
            switch (c) {
                case '{':
                    openCurly++;
                    break;
                case '}':
                    closeCurly++;
                    break;
                case '[':
                    openSquare++;
                    break;
                case ']':
                    closeSquare++;
                    break;
            }
        }

        StringBuilder result = new StringBuilder(input);

        // 补全缺失的右括号
        for (int i = 0; i < openCurly - closeCurly; i++) {
            result.append('}');
        }
        for (int i = 0; i < openSquare - closeSquare; i++) {
            result.append(']');
        }

        // 移除多余的左括号（从开头）
        String resultStr = result.toString();
        for (int i = 0; i < closeCurly - openCurly; i++) {
            int index = resultStr.indexOf('{');
            if (index >= 0) {
                resultStr = resultStr.substring(0, index) + resultStr.substring(index + 1);
            }
        }
        for (int i = 0; i < closeSquare - openSquare; i++) {
            int index = resultStr.indexOf('[');
            if (index >= 0) {
                resultStr = resultStr.substring(0, index) + resultStr.substring(index + 1);
            }
        }

        if (!resultStr.equals(input)) {
            log.warn("Fixed unbalanced brackets: {} -> {}", input, resultStr);
            return resultStr;
        }

        return input;
    }

    /**
     * 修复非法转义字符
     */
    private static String fixIllegalEscapes(String input) {
        StringBuilder result = new StringBuilder();
        boolean inString = false;
        char stringChar = '\0';

        for (int i = 0; i < input.length(); i++) {
            char c = input.charAt(i);

            // 检测字符串边界
            if ((c == '"' || c == '\'') && (i == 0 || input.charAt(i - 1) != '\\')) {
                if (!inString) {
                    inString = true;
                    stringChar = c;
                } else if (c == stringChar) {
                    inString = false;
                }
                result.append(c);
                continue;
            }

            // 处理转义字符
            if (c == '\\' && i + 1 < input.length()) {
                char next = input.charAt(i + 1);

                // 合法的转义字符
                if (inString && (next == '"' || next == '\'' || next == '\\' ||
                        next == '/' || next == 'b' || next == 'f' ||
                        next == 'n' || next == 'r' || next == 't' || next == 'u')) {
                    result.append(c);
                } else if (!inString) {
                    // 字符串外部的反斜杠，保留
                    result.append(c);
                } else {
                    // 非法转义，移除反斜杠
                    log.debug("Removed illegal escape: \\{}", next);
                    // 不添加反斜杠，下次循环会添加 next
                }
            } else {
                result.append(c);
            }
        }

        String resultStr = result.toString();
        if (!resultStr.equals(input)) {
            log.warn("Fixed illegal escapes: {} -> {}", input, resultStr);
        }

        return resultStr;
    }

    /**
     * 安全的逗号分隔参数转换
     */
    private static String convertCommaDelimitedToJsonSafe(String input) {
        // 已经是有效的 JSON 格式
        if (input.startsWith("{") || input.startsWith("[")) {
            return input;
        }

        // 不包含逗号，单个参数
        if (!input.contains(",")) {
            return "[" + input + "]";
        }

        // 包含逗号，尝试解析
        try {
            List<String> parts = parseCommaDelimitedArguments(input);
            if (!parts.isEmpty()) {
                String jsonArray = "[" + String.join(", ", parts) + "]";
                log.info("Converted comma-delimited arguments to JSON array: {} -> {}", input, jsonArray);
                return jsonArray;
            }
        } catch (Exception e) {
            log.debug("Failed to parse as comma-delimited, using as-is: {}", e.getMessage());
        }

        return input;
    }


    /**
     * 解析逗号分隔的参数
     * 支持:
     * - 字符串 (带引号)
     * - 数字
     * - 布尔值
     * - null
     */
    private static List<String> parseCommaDelimitedArguments(String input) {
        List<String> result = new ArrayList<>();
        StringBuilder current = new StringBuilder();
        boolean inQuotes = false;
        char quoteChar = '\0';
        boolean escaped = false;

        for (int i = 0; i < input.length(); i++) {
            char c = input.charAt(i);

            if (escaped) {
                current.append(c);
                escaped = false;
                continue;
            }

            if (c == '\\') {
                current.append(c);
                escaped = true;
                continue;
            }

            if ((c == '"' || c == '\'') && !escaped) {
                if (!inQuotes) {
                    inQuotes = true;
                    quoteChar = c;
                    current.append(c);
                } else if (c == quoteChar) {
                    inQuotes = false;
                    current.append(c);
                } else {
                    current.append(c);
                }
                continue;
            }

            if (c == ',' && !inQuotes) {
                String part = current.toString().trim();
                if (!part.isEmpty()) {
                    result.add(part);
                }
                current = new StringBuilder();
                continue;
            }

            current.append(c);
        }

        // 添加最后一个参数
        String part = current.toString().trim();
        if (!part.isEmpty()) {
            result.add(part);
        }

        return result;
    }

}
