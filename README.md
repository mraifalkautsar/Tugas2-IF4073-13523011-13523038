# IF4073 Tugas 2 - Pemrosesan Citra dalam Ranah Frekuensi

Aplikasi MATLAB dengan GUI untuk LPF, HPF, peningkatan kecerahan, restorasi derau periodik, dan restorasi motion blur pada citra grayscale maupun RGB. GUI menampilkan citra, spektrum frekuensi, mask atau fungsi degradasi, serta hasil pemrosesan.

## Dependensi

- MATLAB R2022a atau lebih baru.
- Image Processing Toolbox untuk tampilan citra dan penghitungan SSIM.

## Cara Menjalankan

1. Buka folder proyek sebagai **Current Folder** di MATLAB dan pastikan folder `dataset/` tersedia.
2. Jalankan perintah berikut pada Command Window.

   ```matlab
   startup
   FrequencyProcessingApp
   ```

3. Pilih bagian B sampai F, pilih citra lalu tekan **Muat Input**, atau gunakan **Buka File...**.
4. Atur metode dan parameternya, lalu tekan **Terapkan filter**. Gunakan **Layar penuh** untuk memperbesar panel dan **Buka Referensi... (opsional)** untuk membandingkan hasil.
