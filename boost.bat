@echo off
setlocal enabledelayedexpansion

:: Ask user for settings
set /p bass="Enter bass boost in dB (0 for none, e.g., 15): "
set /p freq="Enter bass peak frequency in Hz (e.g., 90): "
set /p volume="Enter overall volume adjustment in dB (0 for none, e.g., -10): "
set /p treble="Enter treble reduction in dB (0 for none, e.g., -5): "

:: Create output folder
if not exist boosted mkdir boosted

:: Process each MP3
for %%f in (*.mp3) do (
    :: Wait if there are already 32 ffmpeg jobs running
    :waitLoop
    for /f %%c in ('tasklist /fi "imagename eq ffmpeg.exe" ^| find /c /i "ffmpeg.exe"') do set running=%%c
    if !running! geq 32 (
        timeout /t 2 >nul
        goto waitLoop
    )

    :: Build audio filter dynamically
    set "filter="

    if not "!bass!"=="0" set "filter=equalizer=f=!freq!:width_type=h:width=50:g=!bass!"
    if not "!treble!"=="0" (
        if defined filter set "filter=!filter!,"
        set "filter=!filter!equalizer=f=8000:width_type=h:width=200:g=!treble!"
    )
    if not "!volume!"=="0" (
        if defined filter set "filter=!filter!,"
        set "filter=!filter!volume=!volume!dB"
    )

    :: Start FFmpeg job
    start "" /b cmd /c ffmpeg -y -vn -i "%%f" -af "!filter!" "boosted\%%~nxf"
)

:: Wait for remaining jobs
:finalWait
for /f %%c in ('tasklist /fi "imagename eq ffmpeg.exe" ^| find /c /i "ffmpeg.exe"') do set running=%%c
if !running! gtr 0 (
    timeout /t 2 >nul
    goto finalWait
)

echo.
echo All done! Files saved in 'boosted'.
pause
