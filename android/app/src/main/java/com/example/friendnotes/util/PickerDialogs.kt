package com.example.friendnotes.util

import android.app.DatePickerDialog
import android.app.TimePickerDialog
import android.content.Context
import java.time.LocalDate
import java.time.ZonedDateTime

fun showDatePicker(
    context: Context,
    initialDate: LocalDate,
    onDatePicked: (LocalDate) -> Unit,
) {
    DatePickerDialog(
        context,
        { _, year, month, dayOfMonth ->
            onDatePicked(LocalDate.of(year, month + 1, dayOfMonth))
        },
        initialDate.year,
        initialDate.monthValue - 1,
        initialDate.dayOfMonth,
    ).show()
}

fun showDateTimePicker(
    context: Context,
    initial: ZonedDateTime,
    onPicked: (ZonedDateTime) -> Unit,
) {
    DatePickerDialog(
        context,
        { _, year, month, day ->
            TimePickerDialog(
                context,
                { _, hour, minute ->
                    val picked = initial
                        .withYear(year)
                        .withMonth(month + 1)
                        .withDayOfMonth(day)
                        .withHour(hour)
                        .withMinute(minute)
                    onPicked(roundToFiveMinutes(picked))
                },
                initial.hour,
                initial.minute,
                true,
            ).show()
        },
        initial.year,
        initial.monthValue - 1,
        initial.dayOfMonth,
    ).show()
}
