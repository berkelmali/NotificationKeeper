// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Notification Keeper';

  @override
  String get biometricAuthReason =>
      'Notification Keeper\'ı açmak için kimliğinizi doğrulayın';

  @override
  String get biometricAuthCancelled =>
      'Kimlik doğrulama iptal edildi veya başarısız oldu.';

  @override
  String get biometricNotEnrolled =>
      'Kayıtlı parmak izi, yüz tanıma veya cihaz PIN\'i yok.\nEklemek için Ayarlar → Güvenlik\'e gidin.';

  @override
  String get biometricLockedOut =>
      'Çok fazla başarısız deneme.\nBiraz bekleyip tekrar deneyin.';

  @override
  String get biometricNotAvailable =>
      'Bu cihazda biyometrik donanım bulunmuyor.';

  @override
  String get lockedTitle => 'KİLİTLİ';

  @override
  String get awaitingVerification => 'DOĞRULAMA BEKLENİYOR...';

  @override
  String get archiveProtectedMessage =>
      'Bildirim arşiviniz korunuyor.\nKilidi açmak için dokunun.';

  @override
  String get retryButton => 'TEKRAR DENE';

  @override
  String get tapToUnlock => 'AÇMAK İÇİN DOKUNUN';

  @override
  String get recentCodesTitle => 'SON KODLAR';

  @override
  String get tapToCopy => 'Kopyalamak için dokunun';

  @override
  String get codeCopied => 'Kod kopyalandı';

  @override
  String get dashboardTitle => 'Panel';

  @override
  String get dashboardSubtitle => 'Bildirim özetiniz';

  @override
  String get quietHoursActiveBadge => 'Aktif';

  @override
  String get quietHoursBadge => 'Sessiz';

  @override
  String get statTotal => 'Toplam';

  @override
  String get statToday => 'Bugün';

  @override
  String get statThisWeek => 'Bu Hafta';

  @override
  String get statUnread => 'Okunmamış';

  @override
  String get statCodesToday => 'Bugünkü Kodlar';

  @override
  String get statPriorityToday => 'Bugünkü Öncelikli';

  @override
  String get weeklyTrend => 'Haftalık Eğilim';

  @override
  String get activityHeatmap => 'Aktivite Isı Haritası';

  @override
  String get topApps => 'En Çok Bildirim Gönderenler';

  @override
  String get recentSectionTitle => 'Son Bildirimler';

  @override
  String get seeAll => 'Tümünü Gör';

  @override
  String get emptyStateTitle => 'Henüz bildirim yok';

  @override
  String get emptyStateSubtitle => 'Yakalanan bildirimler burada görünecek';

  @override
  String get archiveTitle => 'Arşiv';

  @override
  String get searchHint => 'Bildirimlerde ara...';

  @override
  String get recentSearches => 'Son Aramalar';

  @override
  String get clearAction => 'Temizle';

  @override
  String get dateGroupToday => 'Bugün';

  @override
  String get dateGroupYesterday => 'Dün';

  @override
  String get dateGroupThisWeek => 'Bu Hafta';

  @override
  String get dateGroupThisMonth => 'Bu Ay';

  @override
  String get dateGroupOlder => 'Daha Eski';

  @override
  String get noNotificationsFound => 'Bildirim bulunamadı';

  @override
  String get tryDifferentSearchTerm => 'Farklı bir arama terimi deneyin';

  @override
  String get capturedNotificationsAppearHere =>
      'Yakalanan bildirimler burada görünecek';

  @override
  String get notificationDeleted => 'Bildirim silindi';

  @override
  String get undoAction => 'GERİ AL';

  @override
  String get copiedToClipboard => 'Panoya kopyalandı';

  @override
  String get filterByDateRange => 'Tarih aralığına göre filtrele';

  @override
  String get snoozedLabel => 'Susturuldu';

  @override
  String get snoozeTooltip => 'Bu uygulamayı sustur';

  @override
  String get snooze1Hour => '1 saat sustur';

  @override
  String get snooze8Hours => '8 saat sustur';

  @override
  String get snooze24Hours => '24 saat sustur';

  @override
  String get cancelSnooze => 'Susturmayı iptal et';

  @override
  String get statStarred => 'Yıldızlı';

  @override
  String get noNotifications => 'Bildirim yok';

  @override
  String appUnsnoozed(String appName) {
    return '$appName susturması kaldırıldı';
  }

  @override
  String appSnoozed(String appName) {
    return '$appName susturuldu';
  }

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get sectionAppearance => 'Görünüm';

  @override
  String get themeDark => 'Koyu';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get sectionSecurity => 'Güvenlik';

  @override
  String get biometricLockTitle => 'Biyometrik Kilit';

  @override
  String get biometricLockSubtitleOn =>
      'Uygulamayı açmak için parmak izi, yüz veya cihaz PIN\'i gerekir';

  @override
  String get biometricLockSubtitleOff =>
      'Arşivi görüntülemeden önce kimlik doğrulama iste';

  @override
  String get sectionQuietHours => 'Sessiz Saatler';

  @override
  String get enableQuietHours => 'Sessiz Saatleri Etkinleştir';

  @override
  String get quietHoursSubtitle =>
      'Belirlenen saatlerde bildirim yakalamayı duraklat';

  @override
  String get startTime => 'Başlangıç Saati';

  @override
  String get endTime => 'Bitiş Saati';

  @override
  String get quietHoursActiveNote =>
      'Sessiz saatler şu anda aktif — bildirimler duraklatıldı';

  @override
  String get captureActiveNote => 'Bildirim yakalama aktif';

  @override
  String get sectionKeywordRadar => 'Anahtar Kelime Radarı';

  @override
  String get instantAlertsTitle => 'Anlık Uyarılar';

  @override
  String get instantAlertsSubtitle =>
      'Bir kod veya öncelikli kelime yakalandığında beni hemen bilgilendir';

  @override
  String get sectionDataManagement => 'Veri Yönetimi';

  @override
  String get clearOldNotificationsTitle => 'Eski Bildirimleri Temizle';

  @override
  String get clearOldNotificationsSubtitle =>
      'Belirli bir süreden eski bildirimleri şimdi kaldır';

  @override
  String get automaticCleanupTitle => 'Otomatik Temizlik';

  @override
  String get automaticCleanupOff => 'Kapalı — bildirimler süresiz saklanır';

  @override
  String automaticCleanupOn(int days) {
    return '$days günden eski bildirimleri her gün kontrol edip otomatik siler';
  }

  @override
  String get exportNotificationsTitle => 'Bildirimleri Dışa Aktar';

  @override
  String get exportNotificationsSubtitle =>
      'Tüm bildirimleri JSON veya CSV olarak dışa aktar';

  @override
  String get clearSearchHistoryTitle => 'Arama Geçmişini Temizle';

  @override
  String get clearSearchHistorySubtitle =>
      'Kaydedilen tüm arama sorgularını kaldır';

  @override
  String get searchHistoryCleared => 'Arama geçmişi temizlendi';

  @override
  String get deleteAllNotificationsTitle => 'Tüm Bildirimleri Sil';

  @override
  String get deleteAllNotificationsSubtitle =>
      'Saklanan tüm bildirimleri kalıcı olarak kaldır';

  @override
  String get sectionBackupRestore => 'Yedekleme ve Geri Yükleme';

  @override
  String get backupNowTitle => 'Şimdi Yedekle';

  @override
  String get backupNowSubtitle =>
      'Her şeyi saklayabileceğiniz veya paylaşabileceğiniz bir dosyaya kaydedin';

  @override
  String get restoreFromBackupTitle => 'Yedekten Geri Yükle';

  @override
  String get restoreFromBackupSubtitle =>
      'Bir yedek dosyasından bildirim ve ayarları ekleyin';

  @override
  String get sectionService => 'Servis';

  @override
  String get notificationAccessTitle => 'Bildirim Erişimi';

  @override
  String get notificationAccessSubtitle => 'Bildirim dinleyici iznini yönetin';

  @override
  String get sectionAbout => 'Hakkında';

  @override
  String get versionLabel => 'Sürüm 2.0.0';

  @override
  String get featureHeatmap => 'Isı Haritası';

  @override
  String get featureTags => 'Etiketler';

  @override
  String get featureQuietHours => 'Sessiz Saatler';

  @override
  String get featureCopy => 'Kopyala';

  @override
  String get featureSearchHistory => 'Arama Geçmişi';

  @override
  String get featureAppDetails => 'Uygulama Detayları';

  @override
  String get featureBiometricLock => 'Biyometrik Kilit';

  @override
  String get featureKeywordRadar => 'Anahtar Kelime Radarı';

  @override
  String get featureAutoCleanup => 'Otomatik Temizlik';

  @override
  String get featureCodeDetection => 'Kod Tespiti';

  @override
  String get sectionLanguage => 'Dil';

  @override
  String get chooseCleanupPeriod =>
      'Bildirimlerin ne kadar geriye kadar saklanacağını seçin.';

  @override
  String get keep7Days => '7 gün sakla';

  @override
  String get keep30Days => '30 gün sakla';

  @override
  String get keep90Days => '90 gün sakla';

  @override
  String get cancelAction => 'İptal';

  @override
  String notificationsDeletedCount(int days) {
    return '$days günden eski bildirimler silindi';
  }

  @override
  String get failedToDeleteNotifications => 'Bildirimler silinemedi';

  @override
  String get deleteAllQuestion => 'Tümü Silinsin mi?';

  @override
  String get deleteAllConfirmBody =>
      'Bu işlem saklanan tüm bildirimleri kalıcı olarak kaldırır. Geri alınamaz.';

  @override
  String get allNotificationsDeleted => 'Tüm bildirimler silindi';

  @override
  String get failedToDelete => 'Silme başarısız oldu';

  @override
  String get deleteAllAction => 'Tümünü Sil';

  @override
  String get backupPassphraseHint =>
      'İsterseniz yedeği bir parola ile koruyun. Şifrelenmemiş dosya için boş bırakın.';

  @override
  String get passphraseOptionalLabel => 'Parola (opsiyonel)';

  @override
  String get createBackupAction => 'Yedek Oluştur';

  @override
  String backupFailed(String error) {
    return 'Yedekleme başarısız oldu: $error';
  }

  @override
  String get selectBackupFileTitle =>
      'Bir Notification Keeper yedek dosyası seçin';

  @override
  String get restoreExplanation =>
      'Bu, yedekteki bildirimleri mevcut arşivinize ekler (önce hiçbir şey silinmez). Bu yedek şifrelenmemişse parolayı boş bırakın.';

  @override
  String get passphraseIfEncryptedLabel => 'Parola (şifreliyse)';

  @override
  String restoredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bildirim geri yüklendi',
    );
    return '$_temp0';
  }

  @override
  String get restoreFailedGeneric => 'Geri yükleme başarısız oldu';

  @override
  String get restoreAction => 'Geri Yükle';

  @override
  String get chooseExportFormat =>
      'Dışa aktarma ve paylaşma için bir format seçin.';

  @override
  String get exportFormatJson => 'JSON';

  @override
  String get exportFormatCsv => 'CSV';

  @override
  String get failedToExportNotifications => 'Bildirimler dışa aktarılamadı';

  @override
  String get automaticCleanupOffToast => 'Otomatik temizlik kapatıldı';

  @override
  String automaticCleanupOnToast(int days) {
    return '$days günden eski bildirimler her gün otomatik silinecek';
  }

  @override
  String get automaticCleanupExplanation =>
      'Arka planda çalışan bir görev her gün kontrol eder ve bundan daha eski bildirimleri kalıcı olarak siler.';

  @override
  String get cleanupOff => 'Kapalı';

  @override
  String get keywordRadarExplanation =>
      'Bu kelimeleri içeren bildirimler öncelikli olarak işaretlenir, böylece bir bakışta fark edebilirsiniz.';

  @override
  String get keywordHint => 'örn. acil, fatura';

  @override
  String get addAction => 'Ekle';

  @override
  String get days3Short => '3 gün';

  @override
  String get days7Short => '7 gün';

  @override
  String get days30Short => '30 gün';

  @override
  String get days90Short => '90 gün';

  @override
  String get navAppsLabel => 'Uygulamalar';

  @override
  String get appsSearchHint => 'Uygulamalarda ara...';

  @override
  String get filterAll => 'Tümü';

  @override
  String get filterMonitored => 'İzlenen';

  @override
  String get filterOff => 'Kapalı';

  @override
  String get selectAllAction => 'Tümünü Seç';

  @override
  String get deselectAllAction => 'Seçimi Kaldır';

  @override
  String get noAppsFound => 'Uygulama bulunamadı';

  @override
  String get onboardTitle1 => 'Hiçbir Bildirimi Kaçırmayın';

  @override
  String get onboardDesc1 =>
      'Notification Keeper, aldığınız her bildirimi yakalayıp arşivler; böylece istediğiniz zaman gözden geçirebilirsiniz.';

  @override
  String get onboardTitle2 => 'Eksiksiz Geçmiş';

  @override
  String get onboardDesc2 =>
      'Bildirim geçmişinizde arama yapın, filtreleyin ve düzenleyin. Yanlışlıkla kapattığınız önemli mesajı bulun.';

  @override
  String get onboardTitle3 => 'Tek Bir İzin Gerekiyor';

  @override
  String get onboardDesc3 =>
      'Bildirimleri yakalayabilmemiz için \"Bildirim Erişimi\" iznine ihtiyacımız var. Verileriniz cihazınızda kalır ve asla paylaşılmaz.';

  @override
  String get openSettingsAction => 'Ayarları Aç';

  @override
  String get iHaveEnabledIt => 'Etkinleştirdim';

  @override
  String get nextAction => 'İleri';

  @override
  String get skipAction => 'Atla';

  @override
  String get permissionStillNotEnabled =>
      'Bildirim erişimi henüz etkin görünmüyor. Listede Notification Keeper için izni açtığınızdan emin olun, sonra geri dönün.';

  @override
  String get checkingPermission => 'Kontrol ediliyor...';

  @override
  String get iosNotSupportedTitle => 'iOS Desteklenmiyor';

  @override
  String get iosNotSupportedBody =>
      'iOS, sistem düzeyindeki kısıtlamalar nedeniyle diğer uygulamaların bildirimlerinin okunmasına izin vermiyor. Bu özellik yalnızca Android\'de kullanılabilir.';

  @override
  String get justNow => 'Az önce';

  @override
  String minutesAgo(int minutes) {
    return '$minutes dk önce';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours sa önce';
  }

  @override
  String daysAgo(int days) {
    return '$days gün önce';
  }

  @override
  String get noTitle => 'Başlık Yok';

  @override
  String get noContent => 'İçerik Yok';

  @override
  String get copiedLabel => 'Kopyalandı';

  @override
  String categoryLabel(String category) {
    return 'Kategori: $category';
  }

  @override
  String get tagsLabel => 'Etiketler';

  @override
  String get starAction => 'Yıldızla';

  @override
  String get unstarAction => 'Yıldızı Kaldır';

  @override
  String get copyAction => 'Kopyala';

  @override
  String get deleteAction => 'Sil';

  @override
  String get tagImportant => 'Önemli';

  @override
  String get tagWork => 'İş';

  @override
  String get tagPersonal => 'Kişisel';

  @override
  String get tagShopping => 'Alışveriş';

  @override
  String get tagSocial => 'Sosyal';

  @override
  String get tagNews => 'Haberler';

  @override
  String get tagFinance => 'Finans';

  @override
  String get tagTravel => 'Seyahat';

  @override
  String get addTagTitle => 'Etiket Ekle';

  @override
  String get enterTagNameHint => 'Etiket adı girin...';

  @override
  String get suggestionsLabel => 'Öneriler';

  @override
  String get heatmapLess => 'Az';

  @override
  String get heatmapMore => 'Çok';

  @override
  String heatmapPeak(String time) {
    return 'Zirve: $time';
  }

  @override
  String heatmapTooltip(String time, int count) {
    return '$time: $count bildirim';
  }

  @override
  String get filterTagged => 'Etiketli';

  @override
  String appsMonitoredCount(int monitored, int total) {
    return '$monitored / $total izleniyor';
  }

  @override
  String quietHoursActiveRange(String start, String end) {
    return 'Etkin: $start - $end';
  }

  @override
  String quietHoursCapturedToday(int count) {
    return 'Bugün sessiz saatlerde $count bildirim sessizce kaydedildi';
  }

  @override
  String get filterRecalled => 'Geri çekilen';

  @override
  String get statRecalled => 'Geri çekilen';

  @override
  String get recalledBadge => 'Geri çekildi';

  @override
  String get recalledExplanation =>
      'Gönderen bu bildirimi geldikten hemen sonra geri çekti; mesaj silinmiş olabilir. Sizdeki kopya burada duruyor.';

  @override
  String recalledAtLabel(String time) {
    return 'Geri çekilme: $time';
  }

  @override
  String get recalledEmptyState => 'Henüz geri çekilen bir şey yok';

  @override
  String get codeShredTitle => 'Kodları otomatik imha et';

  @override
  String get codeShredSubtitle =>
      'Yakalanan doğrulama kodlarını süresi dolunca yok et';

  @override
  String get codeShredExplainer =>
      'Tek kullanımlık bir kod geldikten bir dakika sonra işe yaramaz hâle gelir ama tehlikeli olmayı sürdürür. Süre dolduğunda rakamlar arşivden, dışa aktarımlardan ve sonraki yedeklerden silinir; bildirimin kendisi kalır.';

  @override
  String get codeShredOff => 'Kodları sakla';

  @override
  String codeShredMinutes(int minutes) {
    return '$minutes dakika sonra';
  }

  @override
  String get codeShredHour => '1 saat sonra';

  @override
  String get codeShredDay => '1 gün sonra';

  @override
  String codeShredDone(int count) {
    return '$count kod imha edildi';
  }

  @override
  String get codeShreddedLabel => 'Kod imha edildi';

  @override
  String get filterPhotos => 'Fotoğraflar';

  @override
  String get sectionPhotos => 'Fotoğraflar';

  @override
  String get capturePhotosTitle => 'Mesajlardaki fotoğrafları sakla';

  @override
  String get capturePhotosSubtitle =>
      'Gönderen mesajı silse bile özel bir kopya burada kalır';

  @override
  String photoStorageUsage(int count, String size) {
    return '$count fotoğraf · $size';
  }

  @override
  String get photoPrivacyNote =>
      'Kopyalar bu telefonda gizli olarak, küçültülerek ve konum gibi gizli bilgileri temizlenerek saklanır.';

  @override
  String get deleteAllPhotosTitle => 'Tüm fotoğrafları sil';

  @override
  String get deleteAllPhotosBody =>
      'Saklanan tüm fotoğraflar silinecek. Bildirimlerin kendisi arşivde kalır.';

  @override
  String get photosDeleted => 'Fotoğraflar silindi';

  @override
  String get photoKeptAfterRecall =>
      'Gönderen bu mesajı sildi. Fotoğraf hâlâ burada.';

  @override
  String get sharePhoto => 'Fotoğrafı paylaş';

  @override
  String get closeAction => 'Kapat';

  @override
  String get showSystemApps => 'Sistem uygulamalarını göster';
}
