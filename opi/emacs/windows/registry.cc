/*
 *  Authors:
 *    Leif Kornstaedt <kornstae@ps.uni-sb.de>
 *    Ralf Scheidhauer <scheidhr@dfki.de>
 * 
 *  Copyright:
 *    Leif Kornstaedt, 1999
 *    Ralf Scheidhauer, 1999
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
#include <string.h>

#include "startup.hh"
#include "version.h"

static char *mozartKey = "SOFTWARE\\Mozart Consortium\\Mozart\\" OZVERSION;

char *getRegistry(char *subKey, char *valueName)
{
  char *ret = NULL;

  HKEY hk;
  if (RegOpenKey(HKEY_LOCAL_MACHINE,subKey,&hk) != ERROR_SUCCESS)
    return NULL;

  DWORD type;
  DWORD buf_size = MAX_PATH;
  char buf[MAX_PATH];
  if (RegQueryValueEx(hk,valueName,0,&type,(LPBYTE) buf,&buf_size)
      == ERROR_SUCCESS) {
    switch (type) {
    case REG_SZ:
      ret = strdup(buf);
      break;
    case REG_EXPAND_SZ:
      {
        char buf2[MAX_PATH];
        DWORD n = ExpandEnvironmentStrings(buf, buf2, MAX_PATH);
        if (n != 0 && n != MAX_PATH) {
          ret = strdup(buf2);
        }
      }
      break;
    default:
      break;
    }
  }

  RegCloseKey(hk);

  return ret;
}

char *getRegistry(char *valueName)
{
  return getRegistry(mozartKey, valueName);
}
