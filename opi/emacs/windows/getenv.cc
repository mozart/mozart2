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

#include "startup.hh"

char *ozGetenv(const char *var)
{
  static char buffer[2048];
  int n = GetEnvironmentVariable(var,buffer,sizeof(buffer));
  if (n == 0 || n > sizeof(buffer))
    return NULL;
  else
    return buffer;
}
