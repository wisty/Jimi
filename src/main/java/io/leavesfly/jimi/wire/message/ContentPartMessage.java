package io.leavesfly.jimi.wire.message;

import io.leavesfly.jimi.llm.message.ContentPart;
import lombok.AllArgsConstructor;
import lombok.Data;

/**
 * 内容部分消息包装
 * 用于在 Wire 中传递 ContentPart（如 TextPart）
 */
@Data
@AllArgsConstructor
public class ContentPartMessage implements WireMessage {
    
    /**
     * 内容类型枚举
     */
    public enum ContentType {
        /** 推理内容（思考过程） */
        REASONING,
        /** 正式内容（最终答案） */
        NORMAL
    }
    
    /**
     * 内容部分（可以是 TextPart、ImagePart 等）
     */
    private ContentPart contentPart;
    
    /**
     * 内容类型（默认为正式内容）
     */
    private ContentType contentType;
    
    /**
     * 兼容旧代码的构造函数（默认为正式内容）
     */
    public ContentPartMessage(ContentPart contentPart) {
        this.contentPart = contentPart;
        this.contentType = ContentType.NORMAL;
    }
    
    @Override
    public String getMessageType() {
        return "content_part";
    }
}
