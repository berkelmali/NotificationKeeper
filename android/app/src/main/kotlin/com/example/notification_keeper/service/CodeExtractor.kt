package com.example.notification_keeper.service

/**
 * Finds the one-time code in a notification - the number a person would type.
 *
 * The single regex this replaces took the leftmost "number near a code word",
 * so in "555-1234: Your verification code is 482913" it picked 1234 out of the
 * sender's phone number. It also only knew English words: Turkish messages
 * ("Doğrulama kodunuz: 482913", "tek kullanımlık şifreniz") never registered.
 *
 * Now every 4-8 digit candidate (or 3+3 split by a space or dash) is scored by
 * its distance to the nearest code word, after ruling out what is plainly not
 * a code: parts of phone numbers, amounts of money, times and dates, and -
 * unless nothing else is left - years. The message text is searched first;
 * the title, usually just the sender, only when the text has no answer.
 */
object CodeExtractor {
    /**
     * Code words as stems, written in [fold]ed form: "kod" covers
     * kodu/kodunuz, "sifre" covers şifreniz and SIFRENIZ, "verif" covers
     * verify and verification.
     */
    private val codeWord = Regex(
        "code|c[oó]digo|codice|\\bkod|код|\\botp\\b|passcode|password|\\bpin\\b|verif|one[- ]time|\\b2fa\\b|" +
            "sifre|parola|dogrulama|tek kullanimlik"
    )

    /**
     * 4-8 digits, or 3+3 with a space or dash between. Not glued to other
     * digits through a separator: "555-1234", "+90 532", "12:30", "1.500" and
     * "04.10.2026" are not codes, nor is a group of a spaced phone number
     * ("0850 222 0 600"). A separator after a letter is fine, so the 482913 in
     * "G-482913" counts, and so does "482913 5 dk".
     */
    private val candidate = Regex(
        "(?<![\\d+])(?<!\\d[.,:/-])(?<!\\d{2} )(\\d{3}[ -]\\d{3}|\\d{4,8})(?!\\d)(?![.,:/-]\\d)(?! \\d{2})"
    )

    /** How far (in characters) a number may sit from a code word and still count. */
    private const val WINDOW = 60

    /** "482913 is your code" is common, but "code: 482913" is the safer reading. */
    private const val BEFORE_PENALTY = 3

    /** A year near a code word is only the answer when there is nothing else. */
    private const val YEAR_PENALTY = 1000

    private val currencyAfter = listOf("tl", "try", "usd", "eur", "gbp", "₺", "$", "€", "£")
    private val currencyBefore = listOf('₺', '$', '€', '£')

    fun extract(title: String?, text: String?): String? {
        val body = text.orEmpty()
        return best(body) ?: best("${title.orEmpty()}\n$body")
    }

    /**
     * Lower case with every Turkish i (ı, İ, I) as i and ş ğ ü ö ç as s g u o c,
     * one character for one, so positions stay put. Done by hand rather than
     * with a case-insensitive regex: Android's regex engine (ICU) and the JVM's
     * fold the Turkish i's differently, and SMS often drop the Turkish letters.
     */
    private fun fold(s: String): String = buildString(s.length) {
        for (c in s) {
            append(
                when (c) {
                    'ı', 'İ', 'I' -> 'i'
                    'ş', 'Ş' -> 's'
                    'ğ', 'Ğ' -> 'g'
                    'ü', 'Ü' -> 'u'
                    'ö', 'Ö' -> 'o'
                    'ç', 'Ç' -> 'c'
                    else -> Character.toLowerCase(c)
                }
            )
        }
    }

    private fun best(original: String): String? {
        val s = fold(original)
        val words = codeWord.findAll(s).map { it.range }.toList()
        if (words.isEmpty()) return null

        var bestCode: String? = null
        var bestScore = Int.MAX_VALUE
        for (match in candidate.findAll(s)) {
            if (isMoney(s, match.range)) continue
            val digits = match.value.filter(Char::isDigit)
            var score = words.minOf { distance(it, match.range) }
            if (score > WINDOW) continue
            if (digits.length == 4 && digits.toInt() in 1900..2099) score += YEAR_PENALTY
            if (score < bestScore) {
                bestScore = score
                bestCode = digits
            }
        }
        return bestCode
    }

    private fun distance(word: IntRange, code: IntRange): Int =
        if (code.first > word.last) code.first - word.last
        else word.first - code.last + BEFORE_PENALTY

    private fun isMoney(s: String, code: IntRange): Boolean {
        val after = s.substring(code.last + 1, minOf(s.length, code.last + 6)).trimStart()
        if (currencyAfter.any { after.startsWith(it) }) return true
        val before = s.substring(maxOf(0, code.first - 2), code.first).trim()
        return before.isNotEmpty() && before.last() in currencyBefore
    }
}
