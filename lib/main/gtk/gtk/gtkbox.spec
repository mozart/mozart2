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
     { name  => 'GtkBox',

       super => 'GtkContainer',

       args  => { 'spacing'                       => 'gint',
                  'homogeneous'                   => 'gboolean' },

       fields=> { 'children'                      => 'GList*',
                  'spacing'                       => 'gint16',
                  'homogeneous'                   => 'guint' },

       meths => { 'gtk_box_pack_start'            => { in => ['GtkBox*',
                                                              '!GtkWidget*',
                                                              'gboolean',
                                                              'gboolean',
                                                              'guint'] },
                  'gtk_box_pack_end'              => { in => ['GtkBox*',
                                                              '!GtkWidget*',
                                                              'gboolean',
                                                              'gboolean',
                                                              'guint'] },
                  'gtk_box_pack_start_defaults'   => { in => ['GtkBox*',
                                                              '!GtkWidget*'] },
                  'gtk_box_pack_end_defaults'     => { in => ['GtkBox*',
                                                              '!GtkWidget*'] },
                  'gtk_box_set_homogeneous'       => { in => ['GtkBox*',
                                                              'gboolean'] },
                  'gtk_box_set_spacing'           => { in => ['GtkBox*',
                                                              'gint'] },
                  'gtk_box_reorder_child'         => { in => ['GtkBox*',
                                                              '!GtkWidget*',
                                                              'gint'] },
                  'gtk_box_query_child_packing'   => { in => ['GtkBox*',
                                                              '!GtkWidget*',
                                                              'gboolean*',
                                                              'gboolean*',
                                                              'guint*',
                                                              '%GtkPackType*'] },
                  'gtk_box_set_child_packing'     => { in => ['GtkBox*',
                                                              '!GtkWidget*',
                                                              'gboolean',
                                                              'gboolean',
                                                              'guint',
                                                              '%GtkPackType'] }}}
     );
