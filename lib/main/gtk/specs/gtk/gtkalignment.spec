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
     { name  => 'GtkAlignment',

       super => 'GtkBin',

       args  => { 'xalign'                        => 'gfloat',
                  'yalign'                        => 'gfloat',
                  'xscale'                        => 'gfloat',
                  'yscale'                        => 'gfloat' },

       inits => { 'gtk_alignment_new'             => { in  => ['gfloat',
                                                               'gfloat',
                                                               'gfloat',
                                                               'gfloat'],
                                                       out => 'GtkWidget*' }},

       meths => { 'gtk_alignment_set'             => { in  => ['GtkAlignment*',
                                                               'gfloat',
                                                               'gfloat',
                                                               'gfloat',
                                                               'gfloat'] }}}
     );
