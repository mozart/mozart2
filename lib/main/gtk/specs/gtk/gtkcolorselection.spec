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
     { name  => 'GtkColorSelection',

       super => 'GtkVBox',

       inits => { 'gtk_color_selection_new'                 => { out => 'GtkWidget*' } },

       meths => { 'gtk_color_selection_set_update_policy'   => { in  => ['GtkColorSelection*',
                                                                         '%GtkUpdateType'] },
                  'gtk_color_selection_set_opacity'         => { in  => ['GtkColorSelection*',
                                                                         'gint'] },
                  'gtk_color_selection_set_color'           => { in  => ['GtkColorSelection*',
                                                                         'gdouble*'] },
                  'gtk_color_selection_get_color'           => { in  => ['GtkColorSelection*',
                                                                         'gdouble*'] }}}
     );
