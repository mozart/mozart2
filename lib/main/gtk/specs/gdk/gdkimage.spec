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
     { name  => 'GdkImage',

       super => 'BaseObject',

       inits => { 'gdk_image_new'                  => { in  => ['%GdkImageType',
                                                                'GdkVisual*',
                                                                'gint',
                                                                'gint'],
                                                        out => 'GdkImage*' },
                  'gdk_image_new_bitmap'           => { in  => ['GdkVisual*',
                                                                'gpointer',
                                                                'gint',
                                                                'gint'],
                                                        out => 'GdkImage*' },
                  'gdk_image_get'                  => { in  => ['!GdkWindow*',
                                                                'gint',
                                                                'gint',
                                                                'gint',
                                                                'gint'],
                                                        out => 'GdkImage*' } },

       meths => { 'gdk_image_destroy'              => { in  => ['GdkImage*'] },
                  'gdk_image_put_pixel'            => { in  => ['GdkImage*',
                                                                'gint',
                                                                'gint',
                                                                'gint32'] },
                  'gdk_image_get_pixel'            => { in  => ['GdkImage*',
                                                                'gint',
                                                                'gint'],
                                                        out => 'guint32' } }}
     );
