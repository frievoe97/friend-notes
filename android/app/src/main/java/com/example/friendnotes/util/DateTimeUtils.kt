package com.example.friendnotes.util

import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.ZonedDateTime
import kotlin.math.roundToInt

fun Instant.toLocalDate(zoneId: ZoneId = ZoneId.systemDefault()): LocalDate =
    atZone(zoneId).toLocalDate()

fun roundToFiveMinutes(dateTime: ZonedDateTime): ZonedDateTime {
    val minute = dateTime.minute
    val rounded = (minute / 5f).roundToInt() * 5
    val normalized = if (rounded == 60) {
        dateTime.plusHours(1).withMinute(0)
    } else {
        dateTime.withMinute(rounded)
    }
    return normalized.withSecond(0).withNano(0)
}

fun normalizeMeetingDateRange(
    kindRaw: String,
    start: ZonedDateTime,
    end: ZonedDateTime,
): Pair<ZonedDateTime, ZonedDateTime> {
    val normalizedStart = roundToFiveMinutes(start)
    val normalizedEnd = if (kindRaw == "event") {
        normalizedStart
    } else {
        val roundedEnd = roundToFiveMinutes(end)
        if (roundedEnd.isBefore(normalizedStart)) normalizedStart else roundedEnd
    }
    return normalizedStart to normalizedEnd
}
