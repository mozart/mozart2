@echo off

set SCRIPT_DIR=%~dp0
java -Xms512M -Xmx1024M -Xss1M %JAVA_OPTS% -Dfile.encoding=UTF-8 -jar "%SCRIPT_DIR%sbt-launch.jar" %*
