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
     { name  => 'GtkButton',

       super => 'GtkBin',

       args  => { 'label'                         => 'gchar*',
                  'relief'                        => 'GtkReliefStyle' },

       inits => { 'gtk_button_new'                => { out => 'GtkWidget*' },
                  'gtk_button_new_with_label'     => { in  => ['const gchar*'],
                                                       out => 'GtkWidget*' }},

       meths => { 'gtk_button_pressed'            => { in  => ['GtkButton*'] },
                  'gtk_button_released'           => { in  => ['GtkButton*'] },
                  'gtk_button_clicked'            => { in  => ['GtkButton*'] },
                  'gtk_button_enter'              => { in  => ['GtkButton*'] },
                  'gtk_button_leave'              => { in  => ['GtkButton*'] },
                  'gtk_button_set_relief'         => { in  => ['GtkButton*',
                                                              'GtkReliefStyle'] },
                  'gtk_button_get_relief'         => { in  => ['GtkButton*'],
                                                       out => 'GtkReliefStyle' }}}
     );
