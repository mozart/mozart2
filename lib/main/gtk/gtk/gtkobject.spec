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
     { name  => 'GtkObject',

       super => 'BaseObject',

       args  => { 'user_data'                     => 'gpointer',
                  'signal'                        => 'GtkSignalFunc',
                  'signal_after'                  => 'GtkSignalFunc',
                  'object_signal'                 => 'GtkSignalFunc',
                  'object_signal_after'           => 'GtkSignalFunc' },

       meths => { 'GTK_OBJECT_SET_FLAGS'          => { in  => ['GtkObject*', 'int'] },
                  'GTK_OBJECT_UNSET_FLAGS'        => { in  => ['GtkObject*', 'int'] },
                  'gtk_object_set_flags'          => { in  => ['GtkObject*'] },
                  'gtk_object_unset_flags'        => { in  => ['GtkObject*'] },
                  'gtk_object_ref'                => { in  => ['GtkObject*'] },
                  'gtk_object_unref'              => { in  => ['GtkObject*'] } }}
     );
