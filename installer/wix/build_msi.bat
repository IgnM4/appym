@echo off
setlocal enabledelayedexpansion

set WXS_FILES=Product.wxs Files.wxs Shortcuts.wxs ServiceActions.wxs
for %%F in (files_*.wxs) do (
  if exist "%%F" set WXS_FILES=!WXS_FILES! %%F
)

candle !WXS_FILES! -ext WixUIExtension -ext WixUtilExtension

set WIXOBJS=
for %%F in (!WXS_FILES!) do set WIXOBJS=!WIXOBJS! %%~nF.wixobj

light !WIXOBJS! -ext WixUIExtension -ext WixUtilExtension -o AplicacionPyme.msi

endlocal
