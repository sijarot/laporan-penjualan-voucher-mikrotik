# =====================================================================
# FILE INSTALASI OTOMATIS: install.rsc (VERSI SINKRON PDF TELAH TERUJI)
# =====================================================================

{
    # 1. MEMBUAT SCRIPT UTAMA LAPORAN
    /system script add name="LAPORAN-PENJUALAN-VOUCHER" policy=read,write,policy,test comment="Sistem Laporan Utama" source="
    # --- KONFIGURASI TELEGRAM ---
    :local botToken \"7625720160:AAGTcPgwnb9HwlqWomyZWUsekftLDsI9dLM\"
    :local chatId \"-1003653924418\"

    # --- DEKLARASI VARIABEL AWAL ---
    :local date [/system clock get date]
    :local time [/system clock get time]

    # Mengambil info komponen tanggal asli MikroTik (Format: mmm/dd/yyyy)
    :local meshMonth [:pick \$date 0 3]
    :local meshDay [:pick \$date 4 6]
    :local meshYear [:pick \$date 7 11]

    # --- KONVERSI NAMA BULAN MENJADI ANGKA (UNTUK FORMAT YYYY-MM-DD) ---
    :local monthNum \"00\"
    :local months [:toarray \"jan,feb,mar,apr,may,jun,jul,aug,sep,oct,nov,dec\"]
    :local mIdx [:find \$months \$meshMonth]
    :if (\$mIdx = 0) do={ :set monthNum \"01\" }
    :if (\$mIdx = 1) do={ :set monthNum \"02\" }
    :if (\$mIdx = 2) do={ :set monthNum \"03\" }
    :if (\$mIdx = 3) do={ :set monthNum \"04\" }
    :if (\$mIdx = 4) do={ :set monthNum \"05\" }
    :if (\$mIdx = 5) do={ :set monthNum \"06\" }
    :if (\$mIdx = 6) do={ :set monthNum \"07\" }
    :if (\$mIdx = 7) do={ :set monthNum \"08\" }
    :if (\$mIdx = 8) do={ :set monthNum \"09\" }
    :if (\$mIdx = 9) do={ :set monthNum \"10\" }
    :if (\$mIdx = 10) do={ :set monthNum \"11\" }
    :if (\$mIdx = 11) do={ :set monthNum \"12\" }

    # Merapikan tanggal satu digit agar memiliki angka 0 di depan (misal \" 5\" menjadi \"05\")
    :if ([:pick \$meshDay 0 1] = \" \") do={ :set meshDay (\"0\" . [:pick \$meshDay 1 2]) }

    # Hasil format nama file standar kronologis internasional yang valid diurutkan MikroTik
    :local cleanDate (\$meshYear . \"-\" . \$monthNum . \"-\" . \$meshDay)
    :local fileName (\"laporan_mikhmon_\" . \$cleanDate . \".txt\")
    :local filterComment \"mikhmon\"

    :local totalBaris 0
    :local totalPendapatanHariIni 0
    :local textBuffer \"\"
    :local statusTelegram false

    :global globalMikhmonBulan
    :global globalMikhmonTahun
    :global globalLastMonth
    :global globalLastYear

    :if ([:typeof \$globalMikhmonBulan] = \"nothing\") do={ :set globalMikhmonBulan 0 }
    :if ([:typeof \$globalMikhmonTahun] = \"nothing\") do={ :set globalMikhmonTahun 0 }
    :if ([:typeof \$globalLastMonth] = \"nothing\") do={ :set globalLastMonth \$meshMonth }
    :if ([:typeof \$globalLastYear] = \"nothing\") do={ :set globalLastYear \$meshYear }

    :if (\$globalLastMonth != \$meshMonth) do={
        :set globalMikhmonBulan 0
        :set globalLastMonth \$meshMonth
    }
    :if (\$globalLastYear != \$meshYear) do={
        :set globalMikhmonTahun 0
        :set globalLastYear \$meshYear
    }

    :local daftarHarga [:toarray \"\"]
    :local daftarJumlah [:toarray \"\"]

    # --- 1. PROSES EKSTRAKSI DATA & PENGELOMPOKAN HARGA (PERBAIKAN SINKRONISASI DATA) ---
    :foreach i in=[/system script find where comment~\$filterComment] do={
        :local scriptName [/system script get \$i name]
        
        :local sName \$scriptName
        :local separator \"-|-\"
        :local pos1 [:find \$sName \$separator]
        :local pos2 [:find \$sName \$separator (\$pos1 + 3)]
        :local pos3 [:find \$sName \$separator (\$pos2 + 3)]
        :local startPos (\$pos3 + 3)
        :local subStr [:pick \$sName \$startPos [:len \$sName]]
        :local endPos [:find \$subStr \$separator]
        
        # KUNCI UTAMA: Mengubah ekstrak judul menjadi angka numerik asli (:tonum)
        :local hargaItem [:tonum [:pick \$subStr 0 \$endPos]]
        
        :set totalPendapatanHariIni (\$totalPendapatanHariIni + \$hargaItem)
        :set totalBaris (\$totalBaris + 1)
        
        # PERBAIKAN: Memastikan pembanding indeks menggunakan nilai numerik asli agar tidak salah kelompok
        :local indexHarga [:find \$daftarHarga \$hargaItem]
        :if (\$indexHarga >= 0) do={
            :local jmlLama [:pick \$daftarJumlah \$indexHarga]
            :set (\$daftarJumlah->\$indexHarga) (\$jmlLama + 1)
        } else={
            :set daftarHarga (\$daftarHarga , \$hargaItem)
            :set daftarJumlah (\$daftarJumlah , 1)
        }
        
        :set textBuffer (\$textBuffer . \$scriptName . \"\\r\\n\")
    }

    # --- 2. PENULISAN KE FILE HARIAN ---
    /file print file=\$fileName
    :delay 2s
    :if (\$totalBaris > 0) do={
        /file set \$fileName contents=\$textBuffer
        :delay 1s
        :set globalMikhmonBulan (\$globalMikhmonBulan + \$totalPendapatanHariIni)
        :set globalMikhmonTahun (\$globalMikhmonTahun + \$totalPendapatanHariIni)
    } else={
        /file set \$fileName contents=\"Tidak ada penjualan voucher hari ini.\"
        :delay 1s
    }

    # --- 2B. UPDATE DATABASE FILE OMZET UTAMA (.TXT) ---
    :local omzetFile \"omzet_mikhmon.txt\"
    :local textOmzet (\"Bulan_Ini=\" . \$globalMikhmonBulan . \"\\r\\nTahun_Ini=\" . \$globalMikhmonTahun . \"\\r\\n\")
    /file print file=\$omzetFile
    :delay 2s
    /file set \$omzetFile contents=\$textOmzet
    :delay 1s

    # --- 3. MENYUSUN RINCIAN HARGA UNTUK TELEGRAM ---
    :local rincianPesan \"\"
    :if (\$totalBaris > 0) do={
        :for idx from=0 to=([:len \$daftarHarga] - 1) do={
            :local hg [:pick \$daftarHarga \$idx]
            :local jm [:pick \$daftarJumlah \$idx]
            :local subTot (\$hg * \$jm)
            :set rincianPesan (\$rincianPesan . \"%%E2%%96%%AB%%EF%%B8%%8F%%20Harga%%20Rp%%20\" . \$hg . \"%%20:%%20\" . \$jm . \"%%20pcs%%20%%28Rp%%20\" . \$subTot . \"%%29%%0A\")
        }
    } else={
        :set rincianPesan \"Tidak%%20ada%%20item%%20terjual.%%0A\"
    }

    # --- 4. MENGIRIM NOTIFIKASI KE TELEGRAM ---
    :local pesanTelegram (\"%%F0%%9F%%93%%8A%%20*LAPORAN%%20PENJUALAN%%20VOUCHER*%%0A\" . \
        \"-----------------------------------------%%0A\" . \
        \"Tanggal%%20Laporan%%20:%%20\" . \$date . \"%%0A\" . \
        \"Waktu%%20Eksekusi%%20:%%20\" . \$time . \"%%20WIB%%0A\" . \
        \"-----------------------------------------%%0A\" . \
        \"*RINCIAN%%20VOUCHER%%20HARI%%20INI:*%%0A\" . \
        \$rincianPesan . \
        \"-----------------------------------------%%0A\" . \
        \"Voucher%%20Hari%%20Ini%%20:%%20\" . \$totalBaris . \"%%20pcs%%0A\" . \
        \"Omzet%%20Hari%%20Ini%%20%%20%%20:%%20*Rp%%20\" . \$totalPendapatanHariIni . \"*%%0A\" . \
        \"Omzet%%20Bulan%%20Ini%%20%%20:%%20*Rp%%20\" . \$globalMikhmonBulan . \"*%%0A\" . \
        \"Omzet%%20Tahun%%20Ini%%20%%20:%%20*Rp%%20\" . \$globalMikhmonTahun . \"*%%0A\" . \
        \"-----------------------------------------%%0A\" . \
        \"Nama%%20File%%20Backup%%20:%%20`\" . \$fileName . \"`%%0A\" . \
        \"-----------------------------------------\")

    :if (\$botToken != \"\" and \$chatId != \"\") do={
        :do {
            /tool fetch url=\"https://telegram.org\$botToken/sendMessage?chat_id=\$chatId&text=\$pesanTelegram\" keep-result=no
            :set statusTelegram true
            :delay 1s
        } on-error={
            :log error \"Gagal mengirim laporan Mikhmon ke Telegram. Proses pembersihan dibatalkan.\"
            :if (\$totalBaris > 0) do={
                :set globalMikhmonBulan (\$globalMikhmonBulan - \$totalPendapatanHariIni)
                :set globalMikhmonTahun (\$globalMikhmonTahun - \$totalPendapatanHariIni)
                :set textOmzet (\"Bulan_Ini=\" . \$globalMikhmonBulan . \"\\r\\nTahun_Ini=\" . \$globalMikhmonTahun . \"\\r\\n\")
                /file set \$omzetFile contents=\$textOmzet
            }
        }
    }

    # --- 5. PENGHAPUSAN SCRIPT VOUCHER ---
    :if (\$statusTelegram = true and \$totalBaris > 0) do={
        :foreach i in=[/system script find where comment~\$filterComment] do={
            /system script remove \$i
            :delay 1s
        }
        /system backup save name=autosave_omzet
        :delay 2s
        :log info \"Laporan Mikhmon sukses dikirim. Data database omzet .TXT berhasil diperbarui.\"
    }

    # --- 6. OTOMATIS HAPUS FILE TEPAT 7 HARI YANG LALU (SISTEM TANGGAL SPESIFIK) ---
    :local dDate [/system clock get date]
    :local dDay [:tonum [:pick \$dDate 4 6]]
    :local dMonth [:pick \$dDate 0 3]
    :local dYear [:tonum [:pick \$dDate 7 11]]

    :local oldDay (\$dDay - 7)
    :local oldMonth \$dMonth
    :local oldYear \$dYear

    :if (\$oldDay <= 0) do={
        :local months [:toarray \"jan,feb,mar,apr,may,jun,jul,aug,sep,oct,nov,dec\"]
        :local mIdx [:find \$months \$dMonth]
        
        :set mIdx (\$mIdx - 1)
        :if (\$mIdx < 0) do={ 
            :set mIdx 11 
            :set oldYear (\$oldYear - 1)
        }
        :set oldMonth [:pick \$months \$mIdx]
        
        :local daysInMonth 31
        :if (\$oldMonth=\"apr\" or \$oldMonth=\"jun\" or \$oldMonth=\"sep\" or \$oldMonth=\"nov\") do={ :set daysInMonth 30 }
        :if (\$oldMonth=\"feb\") do={
            :set daysInMonth 28
            :if ((\$oldYear - (\$oldYear / 4) * 4) = 0) do={ :set daysInMonth 29 }
        }
        :set oldDay (\$daysInMonth + \$oldDay)
    }

    :local oldMonthNum \"00\"
    :local monthsList [:toarray \"jan,feb,mar,apr,may,jun,jul,aug,sep,oct,nov,dec\"]
    :local oldMIdx [:find \$monthsList \$oldMonth]
    :if (\$oldMIdx = 0) do={ :set oldMonthNum \"01\" }
    :if (\$oldMIdx = 1) do={ :set oldMonthNum \"02\" }
    :if (\$oldMIdx = 2) do={ :set oldMonthNum \"03\" }
    :if (\$oldMIdx = 3) do={ :set oldMonthNum \"04\" }
    :if (\$oldMIdx = 4) do={ :set oldMonthNum \"05\" }
    :if (\$oldMIdx = 5) do={ :set oldMonthNum \"06\" }
    :if (\$oldMIdx = 6) do={ :set oldMonthNum \"07\" }
    :if (\$oldMIdx = 7) do={ :set oldMonthNum \"08\" }
    :if (\$oldMIdx = 8) do={ :set oldMonthNum \"09\" }
    :if (\$oldMIdx = 9) do={ :set oldMonthNum \"10\" }
    :if (\$oldMIdx = 10) do={ :set oldMonthNum \"11\" }
    :if (\$oldMIdx = 11) do={ :set oldMonthNum \"12\" }

    # Merapikan angka tanggal satu digit agar memiliki angka 0 di depan
    :local oldDayStr [:tostr \$oldDay]
    :if ([:len \$oldDayStr] = 1) do={ :set oldDayStr (\"0\" . \$oldDayStr) }

    # Hasil rekonstruksi teks tanggal 7 hari lalu yang dicari
    :local targetOldDate (\$oldYear . \"-\" . \$oldMonthNum . \"-\" . \$oldDayStr)
    :local targetOldFile (\"laporan_mikhmon_\" . \$targetOldDate . \".txt\")

    # Cari file dengan nama spesifik tersebut, jika ditemukan langsung hapus
    :local targetFind [/file find where name=\$targetOldFile]
    :if ([:len \$targetFind] > 0) do={
        :log warning (\"Menemukan file usang 7 hari lalu. Menghapus: \" . \$targetOldFile)
        /file remove \$targetFind
        :delay 1s
    } else={
        :log info (\"Pembersihan dilewati. File target \" . \$targetOldFile . \" tidak ditemukan.\")
    }
    "

    # 2. MEMBUAT SCHEDULER OTOMATIS (23:55:00)
    /system scheduler add name="JALANKAN-LAPORAN-MIKHMON" start-time=23:59:00 interval=1d policy=read,write,policy,test on-event="/system script run LAPORAN-PENJUALAN-VOUCHER"
    
    :log info "SUKSES: Arsitektur Skrip Laporan Utama Berhasil Terpasang Otomatis dari GitHub!"
}
