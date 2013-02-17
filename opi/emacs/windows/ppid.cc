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

//
// Set the OZPPID environment variable such that an ozengine.exe subprocess
// can check whether its father still lives
//

#include <windows.h>
#include <stdlib.h>
#include <string.h>
#include <io.h>
#include <stdio.h>

#include "startup.hh"

/* win32 does not support process groups,
 * so we set OZPPID such that a subprocess can check whether
 * its father still lives
 */

void publishPid(void) {
  char auxbuf[100];
  int ppid = GetCurrentProcessId();
  sprintf(auxbuf,"%d",ppid);
  SetEnvironmentVariable("OZPPID",strdup(auxbuf));
}
