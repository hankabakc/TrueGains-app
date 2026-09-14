@echo off
for /f "usebackq delims=" %%x in (".env") do (
    echo %%x | findstr /r "^#" >nul
    if errorlevel 1 (
        set %%x
    )
)
.\mvnw.cmd compile spring-boot:run -Dcheckstyle.skip=true
