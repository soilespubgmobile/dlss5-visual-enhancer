# Visual Enhancer v22.0 – tam (çevrimdışı) paket

Klasör düzeni:

```
VisualEnhancer-Tam\
  Baslat.bat
  Visual Enhancer\     <- program klasörü (Türkçe app_pl.qm + ağsız Qt6Network.dll ile)
  Modeller\Merserk\    <- %LOCALAPPDATA%\Merserk klasörünün kopyası
```

Programı her zaman `Baslat.bat` ile açın. Modeller bilgisayarda yoksa ilk açılışta
`%LOCALAPPDATA%\Merserk` içine kopyalanır (yaklaşık 12,6 GB), sonra program açılır.
Modeller zaten varsa doğrudan açılır. Hiçbir şey internetten indirilmez.

Program modelleri yalnızca `%LOCALAPPDATA%\Merserk` altında arar ve bağlantı (junction)
kabul etmez; bu yüzden modeller kopyalanır.
