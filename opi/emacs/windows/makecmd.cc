/*
 *  Author:
 *    Leif Kornstaedt <kornstae@ps.uni-sb.de>
 * 
 *  Copyright:
 *    Leif Kornstaedt, 1999
 * 
 *  Last change:
 *    $Date$ by $Author$
 *    $Revision$
 * 
 *  This file is part of Mozart, an implementation of Oz 3:
 *    http://www.mozart-oz.org
 * 
 *  See the file "LICENSE" or
 *    http://www.mozart-oz.org/LICENSE.html
 *  for information on usage and redistribution
 *  of this file, and for a DISCLAIMER OF ALL
 *  WARRANTIES.
 */

#include <windows.h>
#include <stdio.h>
#include <string.h>

#include "startup.hh"

#define ISSPACE(a)        (a == ' ' || a == '\t')

const char *getCmdLine() {
  char *lpszCmdLine = GetCommandLine();
  // Skip whitespace and application name
  if (lpszCmdLine) {
    while (ISSPACE(*lpszCmdLine)) {
      lpszCmdLine++;
    }

    int isQuoted = 0;
    while (*lpszCmdLine != '\0' && (!ISSPACE(*lpszCmdLine) || isQuoted)) {
      if (*lpszCmdLine == '\"')
        isQuoted = !isQuoted;
      lpszCmdLine++;
    }
    return lpszCmdLine;
  } else {
    return "";
  }
}

char *makeCmdLine(bool isWrapper) {
  static char buffer[1024];

  const char *args = getCmdLine();
  if (isWrapper) {
    sprintf(buffer,"ozengine.exe \"");
    int len = strlen(buffer);
    GetModuleFileName(NULL, buffer+len, sizeof(buffer)-len);
    strcat(buffer,"\"");
    if (args[0] != '\0') {
      strcat(buffer," ");
      strcat(buffer,args);
    }
  } else {
    sprintf(buffer,"ozengine.exe ");
    if (args[0] == '\0') {
      panic(false,"Usage: ozengine <url> <args>");
    }
    strcat(buffer,getCmdLine());
  }

  return buffer;
}
