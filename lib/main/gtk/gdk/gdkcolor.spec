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
     { name  => 'GtkColor',

       args  => { 'type'                           => 'GtkWindowType' },

       fields => { 'pixel'                         => 'gulong',
                   'red'                           => 'gushort',
                   'green'                         => 'gushort',
                   'blue'                          => 'gushort' },

       inits => { 'gtk_window_new'                 => { in  => ['gushort',
                                                                'gushort',
                                                                'gushort'] } }}
     );
