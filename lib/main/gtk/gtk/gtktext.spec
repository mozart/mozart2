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
     { name  => 'GtkText',

       super => 'GtkEditable',

       args  => { 'hadjustment'                   => 'GtkAdjustment',
                  'vadjustment'                   => 'GtkAdjustment',
                  'line_wrap'                     => 'gboolean',
                  'word_wrap'                     => 'gboolean' },

       inits => { 'gtk_text_new'                  => { in  => ['GtkAdjustment*',
                                                               'GtkAdjustment*'],
                                                       out => 'GtkWidget*' } },

       meths => { 'gtk_text_set_editable'         => { in  => ['GtkText*',
                                                               'gboolean'] },
                  'gtk_text_set_word_wrap'        => { in  => ['GtkText*',
                                                               'gint'] },
                  'gtk_text_set_line_wrap'        => { in  => ['GtkText*',
                                                               'gint'] },
                  'gtk_text_set_adjustments'      => { in  => ['GtkText*',
                                                               '!GtkAdjustment*',
                                                               '!GtkAdjustment*'] },
                  'gtk_text_set_point'            => { in  => ['GtkText*',
                                                               'guint'] },
                  'gtk_text_get_point'            => { in  => ['GtkText*'],
                                                       out => 'guint' },
                  'gtk_text_get_length'           => { in  => ['GtkText*'],
                                                       out => 'guint' },
                  'gtk_text_freeze'               => { in  => ['GtkText*'] },
                  'gtk_text_thaw'                 => { in  => ['GtkText*'] },
                  'gtk_text_insert'               => { in  => ['GtkText*',
                                                               '!GdkFont*',
                                                               '!GdkColor*',
                                                               '!GdkColor*',
                                                               'const gchar*',
                                                               'gint'] },
                  'gtk_text_backward_delete'      => { in  => ['GtkText*',
                                                               'guint'] },
                  'gtk_text_foreward_delete'      => { in  => ['GtkText*',
                                                               'guint'] },
                  'GTK_TEXT_INDEX'                => { in  => ['GtkText*',
                                                               'guint'] } }}
     );
