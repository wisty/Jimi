package io.leavesfly.jimi.llm;

import io.leavesfly.jimi.config.LLMProviderConfig;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * RateLimiter 单元测试
 */
class RateLimiterTest {

    @Test
    void testRateLimitWithinWindow() {
        // 配置：1000ms 窗口内最多 3 次请求，超限休眠 500ms
        LLMProviderConfig.RateLimitConfig config = LLMProviderConfig.RateLimitConfig.builder()
                .windowMs(1000)
                .maxRequests(3)
                .sleepMs(500)
                .build();

        RateLimiter limiter = new RateLimiter(config);

        // 快速发送 3 个请求，应该都能立即通过
        long start = System.currentTimeMillis();
        limiter.acquirePermit();  // 第1次
        limiter.acquirePermit();  // 第2次
        limiter.acquirePermit();  // 第3次
        long elapsed = System.currentTimeMillis() - start;

        // 前3次请求应该很快完成（小于100ms）
        assertTrue(elapsed < 100, "前3次请求应该快速通过");
        assertEquals(3, limiter.getCurrentRequestCount());
    }

    @Test
    void testRateLimitExceeded() throws InterruptedException {
        // 配置：1000ms 窗口内最多 2 次请求，超限休眠 300ms
        LLMProviderConfig.RateLimitConfig config = LLMProviderConfig.RateLimitConfig.builder()
                .windowMs(1000)
                .maxRequests(2)
                .sleepMs(300)
                .build();

        RateLimiter limiter = new RateLimiter(config);

        // 发送 2 次请求，应该快速通过
        long start = System.currentTimeMillis();
        limiter.acquirePermit();  // 第1次
        limiter.acquirePermit();  // 第2次
        long elapsed1 = System.currentTimeMillis() - start;
        assertTrue(elapsed1 < 100, "前2次请求应该快速通过");

        // 第3次请求应该触发限流
        start = System.currentTimeMillis();
        limiter.acquirePermit();  // 第3次，应该休眠300ms
        long elapsed2 = System.currentTimeMillis() - start;
        
        // 应该休眠了大约300ms（允许误差±100ms）
        assertTrue(elapsed2 >= 250, "第3次请求应该触发休眠，实际耗时: " + elapsed2 + "ms");
        assertTrue(elapsed2 <= 400, "休眠时间不应超过400ms，实际耗时: " + elapsed2 + "ms");
    }

    @Test
    void testWindowSliding() throws InterruptedException {
        // 配置：500ms 窗口内最多 2 次请求
        LLMProviderConfig.RateLimitConfig config = LLMProviderConfig.RateLimitConfig.builder()
                .windowMs(500)
                .maxRequests(2)
                .sleepMs(200)
                .build();

        RateLimiter limiter = new RateLimiter(config);

        // 发送 2 次请求
        limiter.acquirePermit();
        limiter.acquirePermit();
        assertEquals(2, limiter.getCurrentRequestCount());

        // 等待窗口过期
        Thread.sleep(600);

        // 窗口已过期，计数应该清零
        assertEquals(0, limiter.getCurrentRequestCount());

        // 现在应该可以再次发送 2 次请求
        limiter.acquirePermit();
        limiter.acquirePermit();
        assertEquals(2, limiter.getCurrentRequestCount());
    }

    @Test
    void testReset() {
        LLMProviderConfig.RateLimitConfig config = LLMProviderConfig.RateLimitConfig.builder()
                .windowMs(1000)
                .maxRequests(5)
                .sleepMs(200)
                .build();

        RateLimiter limiter = new RateLimiter(config);

        // 发送几次请求
        limiter.acquirePermit();
        limiter.acquirePermit();
        limiter.acquirePermit();
        assertEquals(3, limiter.getCurrentRequestCount());

        // 重置
        limiter.reset();
        assertEquals(0, limiter.getCurrentRequestCount());

        // 重置后应该可以正常使用
        limiter.acquirePermit();
        assertEquals(1, limiter.getCurrentRequestCount());
    }

    @Test
    void testConcurrentAccess() throws InterruptedException {
        // 配置：1000ms 窗口内最多 10 次请求
        LLMProviderConfig.RateLimitConfig config = LLMProviderConfig.RateLimitConfig.builder()
                .windowMs(1000)
                .maxRequests(10)
                .sleepMs(200)
                .build();

        RateLimiter limiter = new RateLimiter(config);

        // 创建多个线程并发请求
        Thread[] threads = new Thread[3];
        for (int i = 0; i < threads.length; i++) {
            threads[i] = new Thread(() -> {
                for (int j = 0; j < 2; j++) {
                    limiter.acquirePermit();
                }
            });
        }

        // 启动所有线程
        for (Thread thread : threads) {
            thread.start();
        }

        // 等待所有线程完成
        for (Thread thread : threads) {
            thread.join();
        }

        // 总共6次请求，窗口内最多10次，所以应该剩下6次或更少（取决于时间）
        int count = limiter.getCurrentRequestCount();
        assertTrue(count <= 10, "窗口内请求数不应超过限制，当前: " + count);
        assertTrue(count >= 6, "并发请求应该都被记录，当前: " + count);
    }
}
