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
     { name  => 'GtkAdjustment',

       super => 'GtkData',

       inits => { 'gtk_adjustment_new'            => { in  => ['gfloat',
                                                               'gfloat',
                                                               'gfloat',
                                                               'gfloat',
                                                               'gfloat',
                                                               'gfloat'],
                                                       out => 'GtkObject*' }},

       meths => { 'gtk_adjustment_value'          => { in  => ['GtkAdjustment*',
                                                               'gfloat'] },
                  'gtk_adjustment_clamp_page'     => { in  => ['GtkAdjustment*',
                                                               'gfloat',
                                                               'gfloat'] },
                  'gtk_adjustment_changed'        => { in  => ['GtkAdjustment*'] },
                  'gtk_adjustment_value_changed'  => { in  => ['GtkAdjustment*'] }}}
     );
