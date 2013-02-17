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

void panic(bool isSystem, const char *format, ...)
{
  va_list argList;
  char buf[1024];

  va_start(argList, format);
  vsprintf(buf, format, argList);

  if (isSystem) {
    LPVOID lpMsgBuf;
    FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER |
                  FORMAT_MESSAGE_FROM_SYSTEM |
                  FORMAT_MESSAGE_IGNORE_INSERTS,
                  NULL,
                  GetLastError(),
                  MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                  (LPTSTR) &lpMsgBuf,
                  0,
                  NULL);
    strcat(buf, (LPTSTR) lpMsgBuf);
    LocalFree(lpMsgBuf);
  }

  if (console) {
    fprintf(stderr,"Fatal Error: %s\n",buf);
  } else {
    MessageBeep(MB_ICONEXCLAMATION);
    MessageBox(NULL, buf, "Mozart Fatal Error",
               MB_ICONSTOP | MB_SETFOREGROUND);
  }

  ExitProcess(1);
}
