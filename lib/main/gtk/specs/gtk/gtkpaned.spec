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
     { name  => 'GtkPaned',

       super => 'GtkContainer',

       meths => { 'gtk_paned_add1'                => { in  => ['GtkPaned*',
                                                               'GtkWidget*'] },
                  'gtk_paned_add2'                => { in  => ['GtkPaned*',
                                                               'GtkWidget*'] },
#                 'gtk_paned_handle_size'         # old name, not supported
#                 'gtk_paned_gutter_size'         # old name, not supported
#                 'gtk_paned_compute_position'    # internal function
                  'gtk_paned_pack1'               => { in  => ['GtkPaned*',
                                                               'GtkWidget*',
                                                               'gboolean',
                                                               'gboolean'] },
                  'gtk_paned_pack2'               => { in  => ['GtkPaned*',
                                                               'GtkWidget*',
                                                               'gboolean',
                                                               'gboolean'] },
                  'gtk_paned_set_gutter_size'     => { in  => ['GtkPaned*',
                                                               'guint16'] },
                  'gtk_paned_set_handle_size'     => { in  => ['GtkPaned*',
                                                               'guint16'] },
                  'gtk_paned_set_position'        => { in  => ['GtkPaned*',
                                                               'gint'] }}}
     );
