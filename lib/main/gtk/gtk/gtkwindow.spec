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
     { name  => 'GtkWindow',

       super => 'GtkBin',

       args  => { 'type'                           => 'GtkWindowType',
                  'title'                          => 'gchar*',
                  'auto_shrink'                    => 'gboolean',
                  'allow_shrink'                   => 'gboolean',
                  'allow_grow'                     => 'gboolean',
                  'modal'                          => 'gboolean',
                  'window_position'                => 'GtkWindowPosition'},

       inits => { 'gtk_window_new'                 => { in  => ['GtkWindowType'],
                                                        out => 'GtkWidget*' }},

       meths => { 'gtk_window_set_title'           => { in  => ['GtkWindow*',
                                                                'const gchar*'] },
                  'gtk_window_set_wmclass'         => { in  => ['GtkWindow*',
                                                                'const gchar',
                                                                'const gchar'] },
                  'gtk_window_set_focus'           => { in  => ['GtkWindow*',
                                                                '!GtkWidget*'] },
                  'gtk_window_set_default'         => { in  => ['GtkWindow*',
                                                                '!GtkWidget*'] },
                  'gtk_window_set_policy'          => { in  => ['GtkWindow*',
                                                                'gint',
                                                                'gint',
                                                                'gint'] },
                  'gtk_window_add_accel_group'     => { in  => ['GtkWindow*',
                                                                'GtkAccelGroup'] },
                  'gtk_window_remove_accel_group'  => { in  => ['GtkWindow*',
                                                                'GtkAccelGroup'] },
                  'gtk_window_activate_focus'      => { in  => ['GtkWindow*'],
                                                        out => 'gint' },
                  'gtk_window_activate_default'    => { in  => ['GtkWindow*'],
                                                        out => 'gint' },
                  'gtk_window_set_modal'           => { in  => ['GtkWindow*',
                                                                'gboolean'] },
                  'gtk_window_add_embedded_xid'    => { in  => ['GtkWindow*',
                                                                'guint'] },
                  'gtk_window_remove_embedded_xid' => { in  => ['GtkWindow*',
                                                                'guint'] },
                  'gtk_window_set_default_size'    => { in  => ['GtkWindow*',
                                                                'gint',
                                                                'gint'] },
                  'gtk_window_set_geometry_hints'  => { in  => ['GtkWindow*',
                                                                '!GtkWidget*',
                                                                'GdkGeometry',
                                                                'GdkWindowHints'] },
                  'gtk_window_set_position'        => { in  => ['GtkWindow*',
                                                                'GtkWindowPosition'] },
                  'gtk_window_set_transient_for'   => { in  => ['GtkWindow*',
                                                                '!GtkWindow*'] } }}
     );
