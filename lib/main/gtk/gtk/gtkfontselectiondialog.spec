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
     { name  => 'GtkFontSelectionDialog',

       super => 'GtkWindow',

       inits => { 'gtk_font_selection_dialog_new'                => { in  => ['const gchar*'],
                                                                      out => 'GtkWidget*' } },

       meths => { 'gtk_font_selection_dialog_get_font'           => { in  => ['GtkFontSelectionDialog*'],
                                                                      out => 'GdkFont*' },
                  'gtk_font_selection_dialog_get_font_name'      => { in  => ['GtkFontSelectionDialog*'],
                                                                      out => 'gchar*' },
                  'gtk_font_selection_dialog_set_font_name'      => { in  => ['GtkFontSelectionDialog*',
                                                                              'const gchar*'],
                                                                      out => 'gboolean' },
                  'gtk_font_selection_dialog_get_preview_text'   => { in  => ['GtkFontSelectionDialog*'],
                                                                      out => 'gchar*' },
                  'gtk_font_selection_dialog_set_preview_text'   => { in  => ['GtkFontSelectionDialog*',
                                                                              'const gchar*'] },
                  'gtk_font_selection_dialog_set_filter'         => { in  => ['GtkFontSelectionDialog*',
                                                                              '%GtkFontFilterType',
                                                                              '%GtkFontType',
                                                                              'gchar**',
                                                                              'gchar**',
                                                                              'gchar**',
                                                                              'gchar**',
                                                                              'gchar**',
                                                                              'gchar**'] } }}
     );
