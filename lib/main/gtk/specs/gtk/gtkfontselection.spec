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
     { name  => 'GtkFontSelection',

       super => 'GtkNotebook',

       inits => { 'gtk_font_selection_new'                  => { out => 'GtkWidget*' } },

       meths => { 'gtk_font_selection_get_font'             => { in  => ['GtkFontSelection*'],
                                                                 out => 'GdkFont*' },
                  'gtk_font_selection_get_font_name'        => { in  => ['GtkFontSelection*'],
                                                                 out => 'gchar *' },
                  'gtk_font_selection_set_font_name'        => { in  => ['GtkFontSelection*',
                                                                         'const gchar*'] ,
                                                                 out => 'gboolean' },
                  'gtk_font_selection_get_preview_text'     => { in  => ['GtkFontSelection*'],
                                                                 out => 'gchar*' },
                  'gtk_font_selection_set_preview_text'     => { in  => ['GtkFontSelection*',
                                                                         'const gchar*'] },
                  'gtk_font_selection_set_filter'           => { in  => ['GtkFontSelection*',
                                                                         '%GtkFontFilterType',
                                                                         '%GtkFontType',
                                                                         'gchar**',
                                                                         'gchar**',
                                                                         'gchar**',
                                                                         'gchar**',
                                                                         'gchar**',
                                                                         'gchar**'] } }}
     );
