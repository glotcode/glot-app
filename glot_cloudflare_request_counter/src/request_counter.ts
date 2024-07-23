import { DurableObject } from "cloudflare:workers";


interface State {
    minutely: Period;
    hourly: Period;
    daily: Period;
    totalCount: number;
}

function initState(): State {
    return {
        minutely: minutelyPeriod(),
        hourly: hourlyPeriod(),
        daily: dailyPeriod(),
        totalCount: 0,
    };
}

export class RequestCounter extends DurableObject {
    async fetch(request: Request): Promise<Response> {
        const stats = await this.increment();
        return new Response(JSON.stringify(stats), { status: 200 });
    }

    async increment(): Promise<RequestStats> {
        const now = Date.now();

        let state = await this.ctx.storage.get<State>("state")
        if (!state) {
            state = initState();
        }

        incrementPeriodRequest(state.minutely, now);
        incrementPeriodRequest(state.hourly, now);
        incrementPeriodRequest(state.daily, now);
        state.totalCount++;

        await this.ctx.storage.put("state", state);

        return {
            minutely: getPeriodStats(state.minutely, now),
            hourly: getPeriodStats(state.hourly, now),
            daily: getPeriodStats(state.daily, now),
            totalCount: state.totalCount,
        };
    }
}

interface Period {
    startTimestamp: number
    count: number;
    duration: number;
}

function minutelyPeriod(): Period {
    return {
        startTimestamp: 0,
        count: 0,
        duration: 60 * 1000,
    };
}

function hourlyPeriod(): Period {
    return {
        startTimestamp: 0,
        count: 0,
        duration: 60 * 60 * 1000,
    };
}

function dailyPeriod(): Period {
    return {
        startTimestamp: 0,
        count: 0,
        duration: 24 * 60 * 60 * 1000,
    };
}

function incrementPeriodRequest(period: Period, now: number): void {
    const elapsedTime = now - period.startTimestamp;
    const timeUntilReset = period.duration - elapsedTime;

    if (timeUntilReset <= 0) {
        period.startTimestamp = now;
        period.count = 0;
    }

    period.count++;
}

export interface RequestStats {
    minutely: PeriodStats;
    hourly: PeriodStats;
    daily: PeriodStats;
    totalCount: number;
}

export interface PeriodStats {
    count: number;
    timeUntilReset: number;
}


function getPeriodStats(period: Period, now: number): PeriodStats {
    const elapsedTime = now - period.startTimestamp;
    const timeUntilReset = period.duration - elapsedTime;

    return {
        count: period.count,
        timeUntilReset,
    };
}