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
     { name  => 'GtkWidget',

       super => 'GtkObject',

       meths => { 'gtk_widget_ref'                => { in => ['GtkWidget*'] },
                  'gtk_widget_unref'              => { in => ['GtkWidget*'] },
                  'gtk_widget_destroy'            => { in => ['GtkWidget*'] },
                  'gtk_widget_destroyed'          => { in => ['GtkWidget*',
                                                              'GtkWidget**'] },
                  'gtk_widget_get'                => { in => ['GtkWidget*',
                                                              'GtkArg*'] },
                  'gtk_widget_getv'               => { in => ['GtkWidget*',
                                                              'guint',
                                                              'GtkArg*'] },
#                 'gtk_widget_set'                => { in => ['GtkWidget*',
#                                                             'const gchar*',
#                                                             '...'] },
                  'gtk_widget_setv'               => { in => ['GtkWidget*',
                                                              'guint',
                                                              'GtkArg*'] },
                  'gtk_widget_unparent'           => { in => ['GtkWidget*'] },
                  'gtk_widget_show'               => { in => ['GtkWidget*'] },
                  'gtk_widget_show_now'           => { in => ['GtkWidget*'] },
                  'gtk_widget_hide'               => { in => ['GtkWidget*'] },
                  'gtk_widget_show_all'           => { in => ['GtkWidget*'] },
                  'gtk_widget_hide_all'           => { in => ['GtkWidget*'] },
                  'gtk_widget_map'                => { in => ['GtkWidget*'] },
                  'gtk_widget_unmap'              => { in => ['GtkWidget*'] },
                  'gtk_widget_realize'            => { in => ['GtkWidget*'] },
                  'gtk_widget_queue_draw'         => { in => ['GtkWidget*'] },
                  'gtk_widget_queue_resize'       => { in => ['GtkWidget*'] },
                  'gtk_widget_draw'               => { in => ['GtkWidget*',
                                                              'GdkRectangle*'] },
                  'gtk_widget_draw_focus'         => { in => ['GtkWidget*'] },
                  'gtk_widget_draw_default'       => { in => ['GtkWidget*'] },
                  'gtk_widget_size_request'       => { in => ['GtkWidget*',
                                                              'GtkRequisition*'] },
                  'gtk_widget_set_uposition'      => { in => ['GtkWidget*',
                                                              'gint',
                                                              'gint'] },
                  'gtk_widget_set_usize'          => { in => ['GtkWidget*',
                                                              'gint',
                                                              'gint'] }}}
     );
