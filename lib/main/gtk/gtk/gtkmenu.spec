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
     { name  => 'GtkMenu',

       super => 'GtkMenuShell',

       inits => { 'gtk_menu_new'                  => { out => 'GtkWidget*' } },

       meths => { 'gtk_menu_append'               => { in  => ['GtkMenu*',
                                                               '!GtkWidget*'] },
                  'gtk_menu_prepend'              => { in  => ['GtkMenu*',
                                                               '!GtkWidget*'] },
                  'gtk_menu_insert'               => { in  => ['GtkMenu*',
                                                               '!GtkWidget*',
                                                               'gint'] },
                  'gtk_menu_reorder_child'        => { in  => ['GtkMenu*',
                                                               '!GtkWidget*',
                                                               'gint'] },
                  'gtk_menu_popup'                => { in  => ['GtkMenu*',
                                                               '!GtkWidget*',
                                                               '!GtkWidget*',
                                                               'GtkMenuPositionFunc',
                                                               'gpointer',
                                                               'guint',
                                                               'guint32'] },
                  'gtk_menu_set_accel_group'      => { in  => ['GtkMenu*',
                                                               'GtkAccelGroup*'] },
                  'gtk_menu_set_title'            => { in  => ['GtkMenu*',
                                                               'const gchar*'] },
                  'gtk_menu_popdown'              => { in  => ['GtkMenu*'] },
                  'gtk_menu_reposition'           => { in  => ['GtkMenu*'] },
                  'gtk_menu_get_active'           => { in  => ['GtkMenu*'],
                                                       out => 'GtkWidget' },
                  'gtk_menu_set_active'           => { in  => ['GtkMenu*',
                                                               'guint'] },
                  'gtk_menu_set_tearoff_state'    => { in  => ['GtkMenu*',
                                                               'gboolean'] },
                  'gtk_menu_attach_to_widget'     => { in  => ['GtkMenu*',
                                                               '!GtkWidget*',
                                                               'GtkMenuDetachFunc'] },
                  'gtk_menu_detach'               => { in  => ['GtkMenu*'] },
                  'gtk_menu_get_attach_widget'    => { in  => ['GtkMenu*'],
                                                       out => 'GtkWidget*' } }}
     );
