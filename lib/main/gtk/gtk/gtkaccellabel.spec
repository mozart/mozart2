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
     { name  => 'GtkAccelLabel',

       super => 'GtkLabel',

       args  => { 'accel_widget'                          => 'GtkWidget' },

       inits => { 'gtk_accel_label_new'                   => { in  => ['const gchar*'],
                                                               out => 'GtkWidget*' }},

       meths => { 'gtk_accel_label_set_accel_widget'      => { in  => ['GtkAccelLabel*',
                                                                       '!GtkWidget*'] },
                  'gtk_accel_label_get_accel_width'       => { in  => ['GtkAccelLabel*'],
                                                               out => 'guint' },
                  'gtk_accel_label_refetch'               => { in  => ['GtkAccelLabel*'],
                                                               out => 'gboolean' } }}
     );
