package com.gym.v2.core.service;

import io.sentry.Sentry;
import org.springframework.stereotype.Service;

/**
 * Sentry tabanlı LogService gerçeklemesi. "Pure Java" politikasına uygundur.
 */
@Service
public class SentryLogServiceImpl implements LogService {

	@Override
	public void error(Throwable ex) {
		Sentry.captureException(ex);
	}

	@Override
	public void info(String message) {
		Sentry.captureMessage(message);
	}

}
