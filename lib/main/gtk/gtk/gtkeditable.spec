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
     { name  => 'GtkEditable',

       super => 'GtkWidget',

       args  => { 'text_position'                     => 'gint',
                  'editable'                          => 'gboolean' },

       meths => { 'gtk_editable_select_region'        => { in  => ['GtkEditable*',
                                                                   'gint',
                                                                   'gint'] },
                  'gtk_editable_insert_text'          => { in  => ['GtkEditable*',
                                                                   'const gchar*',
                                                                   'gint',
                                                                   'gint*'] },
                  'gtk_editable_delete_text'          => { in  => ['GtkEditable*',
                                                                   'gint',
                                                                   'gint'] },
                  'gtk_editable_get_chars'            => { in  => ['GtkEditable*',
                                                                   'gint',
                                                                   'gint'],
                                                           out => 'gchar *' },
                  'gtk_editable_cut_clipboard'        => { in  => ['GtkEditable*'] },
                  'gtk_editable_copy_clipboard'       => { in  => ['GtkEditable*'] },
                  'gtk_editable_paste_clipboard'      => { in  => ['GtkEditable*'] },
                  'gtk_editable_claim_selection'      => { in  => ['GtkEditable*',
                                                                   'gboolean',
                                                                   'gint32'] },
                  'gtk_editable_delete_selection'     => { in  => ['GtkEditable*'] },
                  'gtk_editable_changed'              => { in  => ['GtkEditable*'] },
                  'gtk_editable_set_position'         => { in  => ['GtkEditable*',
                                                                   'gint'] },
                  'gtk_editable_get_position'         => { in  => ['GtkEditable*'],
                                                           out => ['gint'] },
                  'gtk_editable_set_editable'         => { in  => ['GtkEditable*',
                                                                   'gboolean'] } }}
     );
