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
     { name  => 'GtkEntry',

       super => 'GtkEditable',

       args  => { 'max_length'                    => 'guint',
                  'visibility'                    => 'GtkWidget' },

       inits => { 'gtk_entry_new'                 => { out => 'GtkWidget*' },
                  'gtk_entry_new_with_max_length' => { in  => ['guint16'],
                                                       out => 'GtkWidget*' } },

       meths => { 'gtk_entry_set_text'            => { in  => ['GtkEntry*',
                                                               'const gchar*'] },
                  'gtk_entry_append_text'         => { in  => ['GtkEntry*',
                                                               'const gchar*'] },
                  'gtk_entry_prepend_text'        => { in  => ['GtkEntry*',
                                                               'const gchar*'] },
                  'gtk_entry_set_position'        => { in  => ['GtkEntry*',
                                                               'gint'] },
                  'gtk_entry_get_text'            => { in  => ['GtkEntry*'],
                                                       out => 'gchar*' },
                  'gtk_entry_select_region'       => { in  => ['GtkEntry*',
                                                               'gint',
                                                               'gint'] },
                  'gtk_entry_set_visibility'      => { in  => ['GtkEntry*',
                                                               'gboolean'] },
                  'gtk_entry_set_editable'        => { in  => ['GtkEntry*',
                                                               'gboolean'] },
                  'gtk_entry_set_max_length'      => { in  => ['GtkEntry*',
                                                               'guint16'] } }}
     );
