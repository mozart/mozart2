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
     { name  => 'GtkContainer',
       super => 'GtkWidget',
       args  => { 'border_width'                        => 'gulong',
                  'resize_mode'                         => 'GtkResizeMode',
                  'child'                               => 'GtkWidget*',
                  'object_signal'                       => 'GtkSignalFunc',
                  'object_signal_after'                 => 'GtkSignalFunc' },

       meths => { 'gtk_container_add'                   => { in => ['GtkContainer*',
                                                                    '!GtkWidget*'] },
                  'gtk_container_remove'                => { in => ['GtkContainer*',
                                                                    '!GtkObject*'] },
                  'gtk_container_set_resize_mode'       => { in => ['GtkContainer*',
                                                                    'GtkResizeMode'] },
                  'gtk_container_check_resize'          => { in => ['GtkContainer*'] },
#                 'gtk_container_foreach'               => { in => ['GtkContainer*'] },
#                 'gtk_container_foreach_full'
                  'gtk_container_children'              => { in => ['GtkContainer*'],
                                                             out => 'Glist*' },
                  'gtk_container_focus'                 => { in => ['GtkContainer*',
                                                                    'GtkDirectionType'] },
                  'gtk_container_set_focus_child'       => { in => ['GtkContainer*',
                                                                    '!GtkWidget*'] },
                  'gtk_container_set_focus_vadjustment' => { in => ['GtkContainer*',
                                                                    '!GtkAdjustment*'] },
                  'gtk_container_set_focus_hadjustment' => { in => ['GtkContainer*',
                                                                    '!GtkAdjustment*'] },
                  'gtk_container_register_toplevel'     => { in => ['GtkContainer*'] },
                  'gtk_container_unregister_toplevel'   => { in => ['GtkContainer*'] },
                  'gtk_container_resize_children'       => { in => ['GtkContainer*'] },
                  'gtk_container_child_type'            => { in => ['GtkContainer*'],
                                                             out => 'GtkType' },
#                 'gtk_container_add_child_arg_type'
#                 'gtk_container_query_child_args'
#                 'gtk_container_child_getv'
#                 'gtk_container_child_setv'
#                 'gtk_container_add_with_args'
#                 'gtk_container_addv'
#                 'gtk_container_child_set'
                  'gtk_container_queue_resize'          => { in => ['GtkContainer*'] },
                  'gtk_container_clear_resize_widgets'  => { in => ['GtkContainer*'] },
#                 'gtk_container_arg_set'
#                 'gtk_container_arg_get'
#                 'gtk_container_child_args_collect'
#                 'gtk_container_child_arg_get_info'
                  'gtk_container_forall'                => { code => 'meth forall(Container Proc) {List.forAll {Container children($)} Proc} end' },
                  'gtk_container_child_composite_name'  => { in => ['GtkContainer*',
                                                                    '!GtkWidget*'],
                                                             out => 'gchar*' },
                  'gtk_container_get_toplevels'         => { in => ['GtkContainer*'],
                                                             out => 'GList*' },
                  'gtk_container_set_border_width'      => { in => ['GtkContainer*'],
                                                             out => 'guint' }}}
     );
