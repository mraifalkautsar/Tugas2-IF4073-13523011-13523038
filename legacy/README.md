# Tugas 1 IF4073 Pemrosesan Citra - Analisis dan Perbaikan Kualitas Citra

Aplikasi berbasis MATLAB untuk analisis dan perbaikan kualitas citra.
Program ini digunakan untuk menganalisis karakteristik citra uji (citra + histogram intensitas), menentukan
teknik enhancement yang sesuai, lalu menerapkannya serta membandingkan hasil sebelum dan
sesudah perbaikan.

## Deskripsi Singkat Program

Program mengimplementasikan lima kelompok teknik *image enhancement* sesuai spesifikasi tugas:

| Kelompok Teknik | Implementasi |
|---|---|
| *Intensity Transformation* | `src/intensity/` |
| *Histogram Equalization* | `src/equalization/` |
| *Histogram Specification/Matching* | `src/specification/` |
| *Image Filtering* dengan *Masking* (linear & non-linear) | `src/filtering/` |
| *Image Arithmetic* (eksplorasi) | `src/arithmetic/` |

Program didesain dan diimplementasikan berdasarkan teknik-teknik yang telah diajarkan di kelas IF4073. Program menyediakan sebuah antarmuka visual untuk memilih citra yang akan diproses, mengatur konfigurasi untuk teknik yang dipilih, melihat citra masukan, serta melihat citra hasil. Selain itu, program juga menyediakan fitur stacking dan export. Stacking memungkinnkan pengguna untuk menerapkan enhancement lagi terhadap image yang telah enhanced dan export memungkinkan pengguna meng-ekspor hasil dari image yang telah di-enhance.

## Dependensi

- **MATLAB** — R2022a atau lebih baru. Versi minimum ini dibutuhkan karena GUI memakai
  `uilistbox` dan properti `Theme` pada `uifigure`.
- **Image Processing Toolbox**.


## Tata Cara Menjalankan Program

1. Buka MATLAB, lalu arahkan *Current Folder* ke folder repositori ini.
2. Jalankan GUI:

   ```matlab
   ImageEnhancementApp
   ```

## Struktur Repositori

```
Tugas1-IF4073-CitraDigital-13523104/
├── dataset/      Citra uji resmi, dikelompokkan per jenis permasalahan
│   ├── 1. Histogram Citra/
│   ├── 2. Kasus 1/
│   ├── 3. Kasus 2/
│   ├── 4. Kasus 3/
│   └── 5. Kasus 4/
├── docs/         Spesifikasi tugas
├── src/          Implementasi teknik enhancement buatan sendiri
│   ├── arithmetic/     imageArithmetic.m
│   ├── equalization/   equalizeGrayscale.m, equalizeLightness.m, equalizeRGB.m
│   ├── filtering/      convolution.m, gaussianKernel.m, medianFilter.m
│   ├── histogram/      computeHistogram.m, plotHistogram.m
│   ├── intensity/      intensityTransform.m
│   ├── specification/  specifyGrayscale.m, specifyHistogram.m
│   └── utils/          appendRecordCsv.m, clipToUint8.m, extractFeature.m,
│                       getLightnessChannel.m, padReplicate.m
├── gui/          Aplikasi GUI beserta pembantunya
│   └── ImageEnhancementApp.m (aplikasi utama), AppState.m, applyEnhancement.m,
│       datasetIndex.m, drawImageAndHistograms.m, imageStatistics.m,
│       presetKernel.m, tempProcess.m
├── scripts/      Skrip eksplorasi dan validasi
├── tests/        Unit test MATLAB
├── config/       Registrasi kasus untuk pemrosesan batch (saat ini kosong)
├── out/          Keluaran program, misalnya rekapan.csv
├── startup.m     Menyiapkan path MATLAB
└── README.md
```
