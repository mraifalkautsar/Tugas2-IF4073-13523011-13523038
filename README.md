# IF4073 Tugas 2 — Pemrosesan Citra dalam Ranah Frekuensi

Aplikasi MATLAB berbasis satu GUI. Bagian **B (low-pass)** dan **C (high-pass)** sudah berjalan untuk citra grayscale maupun RGB dengan penapis Ideal, Gaussian, dan Butterworth. Bagian D–F masih berupa placeholder.

## Menjalankan

Memerlukan MATLAB R2022a atau lebih baru dan Image Processing Toolbox (untuk `imshow`). Dari folder repositori:

```matlab
startup
FrequencyProcessingApp
```

Pilih bagian B/C, pilih citra dari daftar `dataset/<bagian>/input/` lalu **Muat Input**, atau gunakan **Buka File...**. Pilih jenis penapis dan cutoff `D0` (satuan: bin/piksel spektrum); orde bilangan bulat positif ditampilkan hanya untuk Butterworth. Tekan **Terapkan filter**. GUI menampilkan input, spektrum sebelum, fungsi penapis H(u,v), spektrum sesudah, dan hasil. Referensi dapat dibuka manual untuk perbandingan. Bagian D–F tetap tidak dapat diproses.

`radialFilter` membangun sendiri mask radial, lalu menerapkan `fft2`, `fftshift`, perkalian spektrum, `ifftshift`, dan `ifft2` pada setiap kanal. Tidak ada padding: batas citra bersifat periodik (*circular*); ukuran dan rata-rata citra pada LPF tidak berubah. Hasil metode berupa `double` dalam skala intensitas `im2double` tanpa normalisasi atau clipping. Khusus HPF, respons mentahnya bertanda dan hampir nol pada daerah datar; **tampilan GUI menambahkan 0,5** sehingga abu-abu tengah berarti respons nol. Hanya tampilan yang di-clip ke `[0,1]`, bukan hasil komputasi.

Untuk memakai metode dari MATLAB secara langsung:

```matlab
startup
[result, H, spectrumBefore, spectrumAfter] = ...
    radialFilter(imread('image.png'), 'low', 'Butterworth', 30, 2);
```

Jalankan tes tanpa dataset dengan `runtests('tests')`. `dataset/` dan `out/` tidak dilacak Git. `legacy/` merupakan proyek Tugas 1 dan tidak ditambahkan ke MATLAB path.

## Eksperimen LPF dan HPF

```matlab
startup
addpath('scripts')
runFrequencyExperiments
```

Skrip memproses seluruh input B/C menggunakan `radialFilter`, mencari parameter LPF terhadap referensi dengan PSNR dan SSIM, serta mengekspor perbandingan HPF. Hasil CSV, lembar perbandingan, mask, spektrum, citra hasil, dan data mentah MAT disimpan di `out/frequency-experiments/`. Penghitungan SSIM memerlukan Image Processing Toolbox.

Gunakan `runFrequencyExperiments('refine')` untuk menambah pencarian di sekitar kandidat yang sudah tersimpan. Pilihan HPF hasil inspeksi visual dicatat di `docs/hpf-recommendations.csv`; `runFrequencyExperiments('export-hpf')` mengekspor ulang pilihan tersebut beserta perbandingan cutoff di sekitarnya. Analisis dan parameter akhir tersedia di [laporan eksperimen](docs/frequency-filter-experiments.md).
