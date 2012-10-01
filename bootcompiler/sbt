#!/usr/bin/env sh

java ${DEBUG_PARAM} -Xms512M -Xmx1536M -Xss1M -XX:+CMSClassUnloadingEnabled \
  -XX:MaxPermSize=384M ${JAVA_OPTS} -Dfile.encoding=UTF-8 \
  -jar `dirname $0`/sbt-launch.jar "$@"
