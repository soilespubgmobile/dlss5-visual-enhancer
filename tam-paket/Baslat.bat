@echo off
setlocal
chcp 65001 >nul
title Visual Enhancer
rem Modeller ilk calistirmada bu paketten Windows kullanici klasorune kopyalanir.
set "PAKET=%~dp0"
set "KAYNAK=%PAKET%Modeller\Merserk"
set "HEDEF=%LOCALAPPDATA%\Merserk"
set "EKSIK="
for %%M in (visionnext razornext peakmagnetar optimagnetar tinymagnetar moge2) do (
  if not exist "%HEDEF%\Visual Enhancer\Models\%%M\" set "EKSIK=1"
)
if defined EKSIK (
  if not exist "%KAYNAK%\Visual Enhancer\Models\" (
    echo Modeller klasoru bulunamadi: "%KAYNAK%"
    pause
    exit /b 1
  )
  echo Modeller ilk kez kuruluyor ^(yaklasik 12,6 GB^). Bu islem birkac dakika surebilir...
  robocopy "%KAYNAK%" "%HEDEF%" /E /R:1 /W:1 /NFL /NDL /NJH /NP
  if errorlevel 8 (
    echo Kopyalama sirasinda hata olustu. Disk alanini kontrol edin.
    pause
    exit /b 1
  )
  echo Modeller kuruldu.
)
start "" "%PAKET%Visual Enhancer\Visual Enhancer.exe"
endlocal
