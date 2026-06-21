# =====================================================================
# FILE INSTALASI OTOMATIS: install.rsc (VERSI SINKRON PDF TELAH TERUJI)
# =====================================================================

/system script
  add name="LAPORAN-PENJUALAN-VOUCHER" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="

# --- KONFIGURASI TELEGRAM ---
:local botToken \"7625720160:AAGTcPgwnb9HwlqWomyZWUsekftLDsI9dLM\"
:local chatId \"-1003653924418\"

# --- DEKLARASI VARIABEL AWAL ---
:local date [/system clock get date]
:local time [/system clock get time]

:local meshMonth [:pick \$date 0 3]
:local meshDay [:pick \$date 4 6]
:local meshYear [:pick \$date 7 11]

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

:if ([:pick \$meshDay 0 1] = \" \") do={ :set meshDay (\"0\" . [:pick \$meshDay 1 2]) }

:local cleanDate (\$meshYear . \"-\" . \$monthNum . \"-\" . \$meshDay)
:local fileName (\"laporan_mikhmon_\" . \$cleanDate . \".txt\")
:local filterComment \"mikhmon\"

:local totalBaris 0
:local totalPendapatanHariIni 0
:local statusTelegram false

:global globalMikhmonBulan
:global globalMikhmonTahun
:global globalLastMonth
:global globalLastYear

:if ([:typeof \$globalMikhmonBulan] = \"nothing\") do={ :set globalMikhmonBulan 0 }
:if ([:typeof \$globalMikhmonTahun] = \"nothing\") do={ :set globalMikhmonTahun 0 }
:if ([:typeof \$globalLastMonth] = \"nothing\") do={ :set globalLastMonth \$meshMonth }
:if ([:typeof \$globalLastYear] = \"nothing\") do={ :set globalLastYear \$meshYear }

:if (\$globalLastMonth != \$meshMonth) do={ :set globalMikhmonBulan 0; :set globalLastMonth \$meshMonth }
:if (\$globalLastYear != \$meshYear) do={ :set globalMikhmonTahun 0; :set globalLastYear \$meshYear }

:local daftarHarga [:toarray \"\"]
:local daftarJumlah [:toarray \"\"]

# --- 1. SOLUSI UTAMA: EKSPOR SEMUA NAMA SCRIPT SEKALIGUS KE FILE (TEMBUS BATAS 4KB) ---
# Perintah ini akan mencetak seluruh daftar nama script bermarkah mikhmon langsung ke file laporan harian
:execute  {/system script print where comment~\"mikhmon\"} file=\$fileName
:delay 3s

# --- 2. PROSES HITUNG OMZET & RINCIAN (HANYA MENGOLAH ANGKA / SANGAT RINGAN) ---
:foreach i in=[/system script find where comment~\$filterComment] do={
    :local scriptName [/system script get \$i name]
    :local sName \$scriptName
    :local separator \"-|-\"
    :local pos1 [:find \$sName \$separator]
    :local pos2 [:find \$sName \$separator (\$pos1 + 3)]
    :local pos3 [:find \$sName \$separator (\$pos2 + 3)]
    
    :if ([:typeof \$pos1] != \"nothing\" && [:typeof \$pos2] != \"nothing\" && [:typeof \$pos3] != \"nothing\") do={
        :local startPos (\$pos3 + 3)
        :local subStr [:pick \$sName \$startPos [:len \$sName]]
        :local endPos [:find \$subStr \$separator]
        
        :if ([:typeof \$endPos] != \"nothing\") do={
            :local hargaItem [:tonum [:pick \$subStr 0 \$endPos]]
            :set totalPendapatanHariIni (\$totalPendapatanHariIni + \$hargaItem)
            :set totalBaris (\$totalBaris + 1)
            
            :local indexHarga [:find \$daftarHarga \$hargaItem]
            :if (\$indexHarga >= 0) do={
                :local jmlLama [:pick \$daftarJumlah \$indexHarga]
                :set (\$daftarJumlah->\$indexHarga) (\$jmlLama + 1)
            } else={
                :set daftarHarga (\$daftarHarga , \$hargaItem)
                :set daftarJumlah (\$daftarJumlah , 1)
            }
        }
    }
}

# --- 3. VALIDASI AKHIR DATA OMZET ---
:if (\$totalBaris > 0) do={
    :set globalMikhmonBulan (\$globalMikhmonBulan + \$totalPendapatanHariIni)
    :set globalMikhmonTahun (\$globalMikhmonTahun + \$totalPendapatanHariIni)
}

# --- 4. UPDATE DATABASE FILE OMZET UTAMA (.TXT) ---
:local omzetFile \"omzet_mikhmon.txt\"
:local textOmzet (\"Bulan_Ini=\" . \$globalMikhmonBulan . \"\r\nTahun_Ini=\" . \$globalMikhmonTahun . \"\r\n\")
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
        :set rincianPesan (\$rincianPesan . \"%E2%96%AB%EF%B8%8F%20Harga%20Rp%20\" . \$hg . \"%20:%20\" . \$jm . \"%20pcs%20(Rp%20\" . \$subTot . \")%0A\")
    }
} else={
    :set rincianPesan \"Tidak%20ada%20item%20terjual.%0A\"
}

# --- 4. MENGIRIM NOTIFIKASI KE TELEGRAM ---
:local pesanTelegram (\"%F0%9F%93%8A%20*LAPORAN%20PENJUALAN%20VOUCHER*%0A\" . \
                     \"-----------------------------------------%0A\" . \
                     \"Tanggal%20Laporan%20:%20\" . \$date . \"%0A\" . \
                     \"Waktu%20Eksekusi%20:%20\" . \$time . \"%20WIB%0A\" . \
                     \"-----------------------------------------%0A\" . \
                     \"*RINCIAN%20VOUCHER%20HARI%20INI:*%0A\" . \
                     \$rincianPesan . \
                     \"-----------------------------------------%0A\" . \
                     \"Voucher%20Hari%20Ini%20:%20\" . \$totalBaris . \"%20pcs%0A\" . \
                     \"Omzet%20Hari%20Ini%20%20%20:%20*Rp%20\" . \$totalPendapatanHariIni . \"*%0A\" . \
                     \"Omzet%20Bulan%20Ini%20%20:%20*Rp%20\" . \$globalMikhmonBulan . \"*%0A\" . \
                     \"Omzet%20Tahun%20Ini%20%20:%20*Rp%20\" . \$globalMikhmonTahun . \"*%0A\" . \
                     \"-----------------------------------------%0A\" . \
                     \"Nama%20File%20Backup%20:%20`\" . \$fileName . \"`%0A\" . \
                     \"-----------------------------------------\")

:if (\$botToken != \"\" and \$chatId != \"\") do={
    :do {
        /tool fetch url=\"https://api.telegram.org/bot\$botToken/sendMessage?chat_id=\$chatId&text=\$pesanTelegram\" keep-result=no
		#/tool fetch url=\"https://api.telegram.org\" http-method=post http-header-field=\"Content-Type: application/x-www-form-urlencoded\" http-data=\"chat_id=\$chatId&parse_mode=Markdown&text=\$pesanTelegram\" check-certificate=no keep-result=no
        :set statusTelegram true
        :delay 1s
    } on-error={
        :log error \"Gagal mengirim laporan Mikhmon ke Telegram. Proses pembersihan dibatalkan.\"
        :if (\$totalBaris > 0) do={
            :set globalMikhmonBulan (\$globalMikhmonBulan - \$totalPendapatanHariIni)
            :set globalMikhmonTahun (\$globalMikhmonTahun - \$totalPendapatanHariIni)
            :set textOmzet (\"Bulan_Ini=\" . \$globalMikhmonBulan . \"\r\nTahun_Ini=\" . \$globalMikhmonTahun . \"\r\n\")
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

# --- 6. OTOMATIS HAPUS FILE TEPAT 7 HARI YANG LALU (SISTEM TANGGAL SPESIFIK - ANTI ACAK) ---
:local dDate [/system clock get date]
:local dDay [:tonum [:pick \$dDate 4 6]]
:local dMonth [:pick \$dDate 0 3]
:local dYear [:tonum [:pick \$dDate 7 11]]

# Hitung mundur tanggal tepat 7 hari yang lalu
:local oldDay (\$dDay - 7)
:local oldMonth \$dMonth
:local oldYear \$dYear

# Logika jika tanggal minus (pindah ke bulan sebelumnya)
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

# Konversi nama bulan lama menjadi format angka dua digit
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

# Merapikan angka tanggal satu digit agar memiliki angka 0 di depan (misal \"7\" menjadi \"07\")
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
# --- PEMBUATAN / UPDATE SCHEDULER OTOMATIS ---
/system scheduler
:if ([:len [find name="JALANKAN-LAPORAN-MIKHMON"]] = 0) do={
  add name="JALANKAN-LAPORAN-MIKHMON" start-time=23:55:00 interval=1d policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon on-event="/system script run LAPORAN-PENJUALAN-VOUCHER"
  :put "Scheduler baru berhasil dibuat."
} else={
		set (find name="JALANKAN-LAPORAN-MIKHMON") start-time=23:55:00 interval=1d policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon on-event="LAPORAN-PENJUALAN-VOUCHER":put "Scheduler lama berhasil diperbarui."
		}
