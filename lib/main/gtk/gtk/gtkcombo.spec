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
     { name  => 'GtkCombo',

       super => 'GtkHBox',

       fields => { 'entry'                                  => 'GtkWidget*',
                   'list'                                   => 'GtkWidget*' },

       inits => { 'gtk_combo_new'                           => { out => 'GtkWidget*' } },

       meths => { 'gtk_combo_set_popdown_strings'           => { in  => ['GtkCombo*',
                                                                         'GList*'] }, # of strings
                  'gtk_combo_set_value_in_list'             => { in  => ['GtkCombo*',
                                                                         'gint',
                                                                         'gint'] },
                  'gtk_combo_set_use_arrows'                => { in  => ['GtkCombo*',
                                                                         'gint'] },
                  'gtk_combo_set_use_arrows_always'         => { in  => ['GtkCombo*',
                                                                         'gint'] },
                  'gtk_combo_set_case_sensitive'            => { in  => ['GtkCombo*',
                                                                         'gint'] },
                  'gtk_combo_set_item_string'               => { in  => ['GtkCombo*',
                                                                         '!GtkItem*',
                                                                         'const gchar*'] },
                  'gtk_combo_disable_activate'              => { in  => ['GtkCombo*'] } }}
     );
