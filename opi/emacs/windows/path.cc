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

#include "startup.hh"

void normalizePath(char *path, bool toUnix)
{
  char from, to;
  if (toUnix) {
    from = '\\';
    to = '/';
  } else {
    from = '/';
    to = '\\';
  }

  for (char *aux = path; *aux != '\0'; aux++) {
    if (*aux == from) {
      *aux = to;
    }
  }
}
