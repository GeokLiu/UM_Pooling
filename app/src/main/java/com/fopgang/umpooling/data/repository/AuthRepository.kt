package com.fopgang.umpooling.data.repository

import com.fopgang.umpooling.SupabaseClientProvider
import com.fopgang.umpooling.data.UmEmail
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.providers.builtin.Email

class AuthRepository {

    // The database repeats this check in a trigger; this one gives an early, clear error.
    suspend fun signUpUMUser(email: String, pass: String): Result<Unit> {
        if (!UmEmail.isValid(email)) {
            return Result.failure(IllegalArgumentException("Registration is restricted to UM email addresses."))
        }
        return suspendRunCatching {
            SupabaseClientProvider.client.auth.signUpWith(Email) {
                this.email = UmEmail.normalize(email)
                this.password = pass
            }
        }
    }

    suspend fun signInUser(email: String, pass: String): Result<Unit> = suspendRunCatching {
        SupabaseClientProvider.client.auth.signInWith(Email) {
            this.email = UmEmail.normalize(email)
            this.password = pass
        }
    }
}
