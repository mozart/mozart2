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
#include <stdio.h>
#include <string.h>
#include <io.h>

#include "startup.hh"

bool console = false;

#define APP_PATHS "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\App Paths"

static char *gnuEmacsKey = "SOFTWARE\\GNU\\Emacs";

static char *xEmacsAppPathKey = APP_PATHS "\\xemacs.exe";

static char *concat(const char *s1, const char *s2)
{
  int i = strlen(s1) + strlen(s2) + 1;
  char *ret = new char[i];
  strcpy(ret,s1);
  strcat(ret,s2);
  return ret;
}

static bool check(char *s)
{
  // return true iff file s exists
  HINSTANCE hInstance = LoadLibraryEx(s,NULL,LOAD_LIBRARY_AS_DATAFILE);
  if (hInstance == NULL)
    return false;
  else {
    FreeLibrary(hInstance);
    return true;
  }
}

static char *getEmacs()
{
  char *emacs;

  // look at OZEMACS environment variable:
  emacs = ozGetenv("OZEMACS");
  if (emacs) {
    if (check(emacs))
      return strdup(emacs);
    else
      panic(false,"Could not execute \"%s\".",emacs);
  }

  // look for installed GNU Emacs:
  emacs = getRegistry(gnuEmacsKey,"emacs_dir");
  if (emacs) {
    emacs = concat(emacs,"\\bin\\runemacs.exe");
    if (check(emacs))
      return emacs;
  }

  // look for installed XEmacs:
  emacs = getRegistry(xEmacsAppPathKey,NULL);
  if (emacs && check(emacs))
    return emacs;

  char *path = getRegistry(xEmacsAppPathKey,"Path");
  if (path)
    while (path[0] != '\0') {
      char *s = strchr(path,';');
      if (s)
        *s = '\0';
      emacs = concat(path,"\\runemacs.exe");
      if (check(emacs))
        return emacs;
      if (!s)
        break;
      path = s + 1;
    }

  panic(false,"Cannot find GNU Emacs or XEmacs.");

  return NULL;
}

int WINAPI
WinMain(HINSTANCE /*hInstance*/, HINSTANCE /*hPrevInstance*/,
        LPSTR /*lpszCmdLine*/, int /*nCmdShow*/)
{
  char buffer[5000];

  initEnv();

  char *emacs  = getEmacs();
  char *ozhome = ozGetenv("OZHOME");
  sprintf(buffer,
          "\"%s\" -l \"%s/share/elisp/oz.elc\" "
          "-l \"%s/share/elisp/oz-server.elc\" "
          "-l \"%s/share/elisp/oz-extra.elc\" "
          "-l \"%s/share/elisp/mozart.elc\" -f run-oz %s",
          emacs,ozhome,ozhome,ozhome,ozhome,getCmdLine());

  STARTUPINFO si;
  ZeroMemory(&si,sizeof(si));
  si.cb = sizeof(si);
  PROCESS_INFORMATION pi;
  if (!CreateProcess(NULL,buffer,NULL,NULL,TRUE,0,NULL,NULL,&si,&pi)) {
    panic(true,"Cannot run '%s'.\n",buffer);
  }

  return 0;
}
