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
     { name  => 'GtkMenuShell',

       super => 'GtkContainer',

       fields => { 'children'                     => 'GList*' },

       meths => { 'gtk_menu_shell_append'         => { in  => ['GtkMenuShell*',
                                                               '!GtkWidget*'] },
                  'gtk_menu_shell_prepend'        => { in  => ['GtkMenuShell*',
                                                               '!GtkWidget*'] },
                  'gtk_menu_shell_insert'         => { in  => ['GtkMenuShell*',
                                                               '!GtkWidget*',
                                                               'gint'] },
                  'gtk_menu_shell_deactivate'     => { in  => ['GtkMenuShell*'] },
                  'gtk_menu_shell_select_item'    => { in  => ['GtkMenuShell*',
                                                               '!GtkWidget*'] },
                  'gtk_menu_shell_activate_item'  => { in  => ['GtkMenuShell*',
                                                               '!GtkWidget*',
                                                               'gboolean'] } }}
     );
