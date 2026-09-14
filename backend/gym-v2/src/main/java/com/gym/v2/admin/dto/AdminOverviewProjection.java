package com.gym.v2.admin.dto;

/**
 * {@code AdminStatsRepository.loadOverview} tek satirlik sonucunu tasiyan projeksiyon.
 */
public interface AdminOverviewProjection {

	long getTotalUsers();

	long getClientCount();

	long getCoachCount();

	long getInactiveUsers();

	long getNewLast24h();

	long getNewLast7d();

	long getNewLast30d();

	long getActiveLast7d();

	long getPairedClients();

	long getActiveSubscriptions();

}
