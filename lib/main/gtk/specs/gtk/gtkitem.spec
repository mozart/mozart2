# -*-perl-*-

# Authors:
#   Andreas Simon (2000)
#
# Copyright:
#   Andreas Simon (2000)
#
# Last change:
#   $Date$
#   $Revision$
#
# This file is part of Mozart, an implementation
# of Oz 3:
#   http://www.mozart-oz.org
#
# See the file "LICENSE" or
#   http://www.mozart-oz.org/LICENSE.html
# for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL
# WARRANTIES.
#

$class =
    (
     { name  => 'GtkItem',

       super => 'GtkBin',

       meths => { 'gtk_item_select'               => { in  => ['GtkItem*'] },
                  'gtk_item_deselect'             => { in  => ['GtkItem*'] },
                  'gtk_item_toggle'               => { in  => ['GtkItem*'] } }}
     );
