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
     { name  => 'GtkColorSelectionDialog',

       super => 'GtkWindow',

       fields => { 'colorsel'                               => 'GtkWidget*',
                   'ok_button'                              => 'GtkWidget*',
                   'cancel_button'                          => 'GtkWidget*',
                   'help_button'                            => 'GtkWidget*' },

       inits => { 'gtk_color_selection_dialog_new'          => { in  => ['const gchar*'],
                                                                 out => 'GtkWidget*' } }}
     );
