del *.log
del *.syntax
del *.av

del oop\*.log
del oop\*.syntax
del oop\*.av

"..\shell_project\ori.exe" -f "..\test\consts.php" -nologo
"..\shell_project\ori.exe" -f "..\test\vars.php" -nologo
"..\shell_project\ori.exe" -f "..\test\operators.php" -nologo
"..\shell_project\ori.exe" -f "..\test\globals.php" -nologo
"..\shell_project\ori.exe" -f "..\test\core.php" -nologo
"..\shell_project\ori.exe" -f "..\test\math.php" -nologo
"..\shell_project\ori.exe" -f "..\test\arrays.php" -nologo
"..\shell_project\ori.exe" -f "..\test\cycles.php" -nologo
"..\shell_project\ori.exe" -f "..\test\foreach.php" -nologo

"..\shell_project\ori.exe" -f "..\test\core_string.php" -nologo
"..\shell_project\ori.exe" -f "..\test\core_array.php" -nologo
"..\shell_project\ori.exe" -f "..\test\evals.php" -nologo
"..\shell_project\ori.exe" -f "..\test\functions.php" -nologo
"..\shell_project\ori.exe" -f "..\test\typed.php" -nologo

"..\shell_project\ori.exe" -f "..\test\leak.php" -nologo

"..\shell_project\ori.exe" -f "..\test\complex1.php" -nologo


"..\shell_project\ori.exe" -f "..\test\oop\constants.php"
"..\shell_project\ori.exe" -f "..\test\oop\static_vars.php"


pause