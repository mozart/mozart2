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
     { name  => 'GtkMisc',

       super => 'GtkWidget',

       args  => { 'xalign'                        => 'gfloat',
                  'yalign'                        => 'gfloat',
                  'xpad'                          => 'gint',
                  'ypad'                          => 'gint' },

       fields=> { 'xalign'                        => 'gfloat',
                  'yalign'                        => 'gfloat',
                  'xpad'                          => 'guint16',
                  'ypad'                          => 'guint16' },

       meths => { 'gtk_misc_set_alignment'        => { in => ['GtkMisc*',
                                                              'gfloat',
                                                              'gfloat'] },
                  'gtk_misc_set_padding'          => { in => ['GtkMisc*',
                                                               'gint',
                                                               'gint'] }}}
     );
