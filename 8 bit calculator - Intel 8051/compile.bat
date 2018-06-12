dir -d /b *asm > log.txt
set /p code=<log.txt
asemw.exe %code% > log.txt
start cmd /c "type log.txt & pause>nul"