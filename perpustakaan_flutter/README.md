1. Model betugas sebagai tempat data yang menyimpan atribut dari book dan loan. Model tidak boleh mengkases view dan tidak boleh ada kode UI di dalamnya
View betugas dalam tampilannya (UI), view dapat memiliki logika UI seperti if-else tetapi tidak boleh memproses logika bisnisnya sendiri(seperti denda keterlambatan). view dapat membaca data dari model melalui viewmodel. view meneruskan aksi user ke viewmodel
ViewModel betugas sebagai jembatan antara model dan view. Jadi viewmodel mengolah data yang ada di model untuk ditampilkan di view dan dapat memproses aksi pengguna, seperti menekan tombol borrow, maka viewnya juga akan langsung berubah. Jadi, setiap state yang berubah akan dikirim ke view unntuk ditampilkan

2. Alasan utamanya adalah dari segi keamanan, karena LoanCard.build() berdada dalam view yang dimana, UI nya dapat diutak atik oleh pengguna. Contohnya, jika dendanya ada 100.000, maka penggunanya dapat edit menjadi 0. Lalu selain itu, view hanya bertugas dalam menampilkan, bukan mengatur perhitungan yang rumit, jika diletakkan di view, perhitungan dendanya harus dihitung berulang-ulang setiap pengguna scroll, padahal hanya cukup ketika ada perubahan state

3. Seharusnya tidak bisa, karena borrowBook() di viewmodel terdapat pengecekan apakah buku sedang dipinjam atau tidak, jika buku belum dikembalikan, borrowBook() akan return false

4. Agar tidak terdapat pengulangan kode yang membuat kode menjadi panjang secara tidak perlu (Don't repeat yourself). Jadi logika bisnisnya diletakkan saja semua di viewmodel, sesuai dengan aturan MVVM 

5. Jika bukunya overdue, maka denda yang dibayar hanya sebanyak hari pengguna tidak mengembalikan buku tersebut(di bawah 6 bulan). Jika missing atau hilang, buku tersebut telah lewat dari 6 bulan pengembalian dan harus membayar denda dengan rincian jumlah hari telat mengembalikan ditambah biaya asli bukunya

6. Akan diubah di viewmodelnya dalam library_view_model.dart, pada line static const int weeklyFineRate = 5000; menjadi static const int weeklyFineRate = 7000;. Karena MVVM memakai single source of truth, dengan mengubah 1 baris ini maka otomatis akan mengubah seluruh perhitungan denda