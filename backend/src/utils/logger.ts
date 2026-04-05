type LogContext = Record<string, unknown>;

const baseLog = (level: "INFO" | "WARN" | "ERROR", message: string, context?: LogContext): void => {
  const payload = {
    level,
    message,
    ...(context ? { context } : {}),
    timestamp: new Date().toISOString()
  };
  console.log(JSON.stringify(payload));
};

export const logger = {
  info: (message: string, context?: LogContext): void => baseLog("INFO", message, context),
  warn: (message: string, context?: LogContext): void => baseLog("WARN", message, context),
  error: (message: string, context?: LogContext): void => baseLog("ERROR", message, context)
};
