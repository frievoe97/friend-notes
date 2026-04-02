package com.example.friendnotes.util

import org.json.JSONArray

object JsonListCodec {
    fun decode(raw: String): List<String> {
        if (raw.isBlank()) return emptyList()
        return try {
            val array = JSONArray(raw)
            buildList {
                for (i in 0 until array.length()) {
                    val value = array.optString(i).trim()
                    if (value.isNotEmpty()) add(value)
                }
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun encode(values: List<String>): String {
        val cleaned = values
            .map { it.trim() }
            .filter { it.isNotEmpty() }
        return JSONArray(cleaned).toString()
    }

    fun normalizedUnique(values: List<String>): List<String> {
        val seen = linkedSetOf<String>()
        val result = mutableListOf<String>()
        values.forEach { value ->
            val normalized = value.trim()
            if (normalized.isEmpty()) return@forEach
            val key = normalized.lowercase()
            if (seen.add(key)) {
                result += normalized
            }
        }
        return result
    }
}
