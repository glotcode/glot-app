import { DurableObject } from "cloudflare:workers";


export interface RateLimitConfig {
    maxRequests: number;
    periodDuration: number;
}

export interface RateLimitStats {
    timeUntilReset: number;
    requestCount: number;
    remainingRequests: number;
}

export class RateLimiter extends DurableObject {
    private startTimestamp: number = 0;
    private requestCount: number = 0;

    async increment(config: RateLimitConfig): Promise<RateLimitStats> {
        const now = Date.now();
        const elapsedTime = now - this.startTimestamp;
        const timeUntilReset = config.periodDuration - elapsedTime;

        if (timeUntilReset <= 0) {
            this.startTimestamp = now;
            this.requestCount = 0;
        }

        this.requestCount++;

        const newTimeUntilReset = config.periodDuration - (now - this.startTimestamp);

        return {
            timeUntilReset: newTimeUntilReset,
            requestCount: this.requestCount,
            remainingRequests: Math.max(0, config.maxRequests - this.requestCount),
        };
    }
}