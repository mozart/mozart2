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
     { name  => 'GtkDrawingArea',

       super => 'GtkWidget',

       inits => { 'gtk_drawing_area_new'                       => { out => 'GtkWidget*' } },

       meths => { 'gtk_drawing_area_size'                      => { in  => ['GtkDrawingArea*',
                                                                            'gint',
                                                                            'gint'] } }}
     );
