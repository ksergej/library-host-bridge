package com.company.library.config;

import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "mq.library")
public class LibraryMqProperties {

    private String requestQueue;
    private String replyQueue;
    private Duration timeout = Duration.ofSeconds(5);

    public String getRequestQueue() {
        return requestQueue;
    }

    public void setRequestQueue(String requestQueue) {
        this.requestQueue = requestQueue;
    }

    public String getReplyQueue() {
        return replyQueue;
    }

    public void setReplyQueue(String replyQueue) {
        this.replyQueue = replyQueue;
    }

    public Duration getTimeout() {
        return timeout;
    }

    public void setTimeout(Duration timeout) {
        this.timeout = timeout;
    }
}
