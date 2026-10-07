package com.example.notification_keeper.service

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class CodeExtractorTest {
    private fun code(text: String, title: String? = null) = CodeExtractor.extract(title, text)

    @Test
    fun `ignores the sender's phone number in the title`() {
        // Seen on the emulator: the old regex returned 1234 here.
        assertEquals("482913", code("Your verification code is 482913. Do not share it.", title = "555-1234"))
    }

    @Test
    fun `reads Turkish bank messages`() {
        assertEquals("482913", code("Tek kullanımlık şifreniz: 482913. Bilgi: 0850 222 0 600"))
        assertEquals("482913", code("Doğrulama kodunuz 482913'tür. Kimseyle paylaşmayın."))
        assertEquals("739102", code("ŞİFRENİZ: 739102"))
        assertEquals("318274", code("TEK KULLANIMLIK SIFRENIZ 318274 DIR"))
        assertEquals("6402", code("GIRIS KODUNUZ: 6402"))
    }

    @Test
    fun `reads Turkish typed without Turkish letters`() {
        assertEquals("4829", code("Dogrulama kodunuz: 4829"))
        assertEquals("552190", code("Tek kullanimlik sifreniz 552190 dir"))
    }

    @Test
    fun `reads other common languages`() {
        assertEquals("482913", code("Tu código es 482913"))
        assertEquals("4829", code("Ваш код: 4829"))
    }

    @Test
    fun `reads a code that comes before the word`() {
        assertEquals("482913", code("482913 is your Instagram code"))
        assertEquals("482913", code("G-482913 is your Google verification code."))
    }

    @Test
    fun `joins a code split in two`() {
        assertEquals("482913", code("Your WhatsApp code: 482-913"))
        assertEquals("482913", code("Your code: 482 913"))
    }

    @Test
    fun `keeps a code followed by a short number`() {
        assertEquals("482913", code("Kodunuz 482913 5 dk geçerlidir"))
    }

    @Test
    fun `skips amounts of money`() {
        assertEquals("739102", code("Hesabınızdan 2500 TL harcama için onay kodunuz: 739102"))
        assertEquals("8841", code("Payment of $1500 needs code 8841"))
    }

    @Test
    fun `skips years, dates, times and phone numbers`() {
        assertEquals("5521", code("© 2026 Acme. Your login code is 5521"))
        assertEquals("482913", code("Kodunuz 04.10.2026 tarihine kadar geçerli: 482913"))
        assertEquals("4829", code("Your code 4829 expires at 12:30"))
        assertEquals("8841", code("Call 555-123-4567 if this wasn't you. Code: 8841"))
    }

    @Test
    fun `finds a code whose word is only in the title`() {
        assertEquals("482913", code("482913", title = "Verification code"))
    }

    @Test
    fun `is not fooled by numbers with no code word`() {
        assertNull(code("Order 48291302 has shipped"))
        assertNull(code("Meeting moved to 1530 in room 2104"))
        assertNull(code(""))
    }

    @Test
    fun `is not fooled by a lone phone number near a code word`() {
        assertNull(code("Şifre sıfırlamak için 0850 222 0 600 numarasını arayın"))
    }

    @Test
    fun `a year counts only when nothing else is there`() {
        assertEquals("2026", code("Your code is 2026"))
    }
}
