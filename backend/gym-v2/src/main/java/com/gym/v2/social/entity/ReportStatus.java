package com.gym.v2.social.entity;

/** Sikayetin karar durumu. */
public enum ReportStatus {

	/** Yonetici henuz bakmadi. */
	PENDING,

	/** Incelendi, islem yapildi. */
	ACTIONED,

	/** Incelendi, islem gerektirmedi. */
	DISMISSED

}
