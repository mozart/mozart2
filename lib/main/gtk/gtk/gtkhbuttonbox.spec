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
     { name  => 'GtkHButtonBox',

       super => 'GtkButtonBox',

       inits => { 'gtk_hbutton_box_new'                        => { out => 'GtkWidget*' } },

       meths => { 'gtk_hbutton_box_get_spacing_default'        => { out => 'gint' },
                  'gtk_hbutton_box_get_layout_default'         => { out => '%GtkButtonBoxStyle' },
                  'gtk_hbutton_box_set_spacing_default'        => { in  => ['gint'] },
                  'gtk_hbutton_box_set_layout_default'         => { in  => ['%GtkButtonBoxStyle'] } }}
     );
