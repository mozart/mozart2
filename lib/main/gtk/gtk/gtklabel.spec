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
     { name  => 'GtkLabel',

       super => 'GtkMisc',

       args  => { 'label'                         => 'gchar*',
                  'pattern'                       => 'gchar*',
                  'justify'                       => 'GtkJustification' },

       inits => { 'gtk_label_new'                 => { in  => ['const gchar*'],
                                                       out => 'GtkPaned*' } },
       meths => { 'gtk_label_set_pattern'         => { in  => ['GtkLabel*',
                                                               'const gchar*'] },
                  'gtk_label_set_justify'         => { in  => ['GtkLabel*',
                                                               'GtkJustification'] },
                  'gtk_label_get'                 => { in  => ['GtkLabel*',
                                                               'gchar**'] },
                  'gtk_label_parse_uline'         => { in  => ['GtkLabel*',
                                                               'const gchar*'],
                                                       out => 'guint' },
                  'gtk_label_set_line_wrap'       => { in  => ['GtkLabel*',
                                                               'gboolean'] },
                  'gtk_label_set_text'            => { in  => ['GtkLabel*',
                                                               'const gchar*'] }}}
     );
