# -*-perl-*-

# Authors:
#   Andreas Simon (2000)
#
# Copyright:
#   Andreas Simon (2000)
#
# Last change:
#   $Date$ by $Author$
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
     { name  => 'GtkFileSelection',

       super => 'GtkWindow',

       fields => { 'fileop_dialog'                          => 'GtkWidget*',
                   'dir_list'                               => 'GtkWidget*',
                   'file_list'                              => 'GtkWidget*',
                   'ok_button'                              => 'GtkWidget*',
                   'cancel_button'                          => 'GtkWidget*',
                   'history_pulldown'                       => 'GtkWidget*',
                   'fileop_c_dir'                           => 'GtkWidget*',
                   'fileop_del_file'                        => 'GtkWidget*',
                   'fileop_ren_file'                        => 'GtkWidget*' },

       inits => { 'gtk_file_selection_new'                  => { in  => ['const gchar*'],
                                                                 out => 'GtkWidget*' } },

       meths => { 'gtk_file_selection_set_filename'         => { in  => ['GtkFileSelection*',
                                                                         'const gchar*'] },
                  'gtk_file_selection_get_filename'         => { in  => ['GtkFileSelection*'],
                                                                 out => 'gchar*' },
                  'gtk_file_selection_complete'             => { in  => ['GtkFileSelection*',
                                                                         'const gchar*'] },
                  'gtk_file_selection_show_fileop_buttons'  => { in  => ['GtkFileSelection*'] },
                  'gtk_file_selection_hide_fileop_buttons'  => { in  => ['GtkFileSelection*'] } }}
     );
