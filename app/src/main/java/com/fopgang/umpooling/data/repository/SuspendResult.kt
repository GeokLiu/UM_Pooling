package com.fopgang.umpooling.data.repository

import kotlinx.coroutines.CancellationException

/** Like runCatching for suspend code, but never swallows coroutine cancellation. */
internal suspend fun <T> suspendRunCatching(block: suspend () -> T): Result<T> = try {
    Result.success(block())
} catch (cancelled: CancellationException) {
    throw cancelled
} catch (e: Exception) {
    Result.failure(e)
}
