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
     { name  => 'GtkTable',

       super => 'GtkContainer',

       args  => { 'n_rows'                        => 'guint',
                  'n_columns'                     => 'guint',
                  'row_spacing'                   => 'guint',
                  'column_spacing'                => 'guint',
                  'homogeneous'                   => 'gboolean' },

       inits => { 'gtk_table_new'                 => { in  => ['guint',
                                                               'guint',
                                                               'gboolean'],
                                                       out => 'GtkWidget*' },
                  'gtk_table_resize'              => { in  => ['GtkTable*',
                                                               'guint',
                                                               'guint'] },
                  'gtk_table_attach'              => { in  => ['GtkTable*',
                                                               '!GtkWidget*',
                                                               'guint',
                                                               'guint',
                                                               'guint',
                                                               'guint',
                                                               'GtkAttachOptions',
                                                               'GtkAttachOptions',
                                                               'guint',
                                                               'guint'] },
                  'gtk_table_attach_defaults'     => { in  => ['GtkTable*',
                                                               '!GtkWidget*',
                                                               'guint',
                                                               'guint',
                                                               'guint',
                                                               'guint'] },
                  'gtk_table_set_row_spacing'     => { in  => ['GtkTable*',
                                                               'guint',
                                                               'guint'] },
                  'gtk_table_set_col_spacing'     => { in  => ['GtkTable*',
                                                               'guint',
                                                               'guint'] },
                  'gtk_table_set_row_spacings'    => { in  => ['GtkTable*',
                                                               'guint'] },
                  'gtk_table_set_col_spacings'    => { in  => ['GtkTable*',
                                                               'guint'] },
                  'gtk_table_set_homogeneous'     => { in  => ['GtkTable*',
                                                               'gboolean'] } }}
     );
