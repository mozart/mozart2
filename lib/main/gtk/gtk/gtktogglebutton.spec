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
     { name  => 'GtkToggleButton',

       super => 'GtkButton',

       args  => { 'active'                         => 'gboolean',
                  'draw_indicator'                 => 'gboolean' },

       inits => { 'gtk_check_button_new'           => { out => 'GtkWidget*' },
                  'gtk_check_button_new_with_labe' => { in  => ['const gchar*'],
                                                        out => 'GtkWidget*' }},

       meths => { 'gtk_toggle_button_set_mode'     => { in  => ['GtkToggleButton*'],
                                                        out => 'gboolean' },
#                 'gtk_toggle_button_set_state'       # only compatibility macro
                  'gtk_toggle_button_toggled'      => { in  => ['GtkToggleButton*'] },
                  'gtk_toggle_button_get_active'   => { in  => ['GtkToggleButton*'],
                                                        out => 'gboolean' },
                  'gtk_toggle_button_set_active'   => { in  => ['GtkToggleButton*',
                                                                'gboolean'] }}}
     );
