del /s "*.o" "*.ppu" "*.dcu" "*.db" "backup" "*.a" "*.local" "*.bak" "*.~*" "*.identcache"
del /s "*.dbg" "ppas.bat" "*.*_" "*.compiled"
php sclear.php
FOR /F "tokens=*" %%G IN ('DIR /B /AD /S __history') DO RMDIR /S /Q "%%G"
FOR /F "tokens=*" %%G IN ('DIR /B /AD /S backup') DO RMDIR /S /Q "%%G"