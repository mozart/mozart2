#!/usr/bin/perl
#
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

use Getopt::Long;

# Regular Expressions (group only without backreferences!)
#$rexp_type        = qr/\w[\w ]+[\*\[\]]*/;
#$rexp_type        = qr/(?:const )?\w+(?:\s*\*+(?=[^\*]))?/;
#$rexp_name        = qr/(?<=\W)\??\w+/;
# We allow '?' as first character of an identifier to mark return values
#$rexp_arg         = qr/\??${rexp_type}/;
#$rexp_arg_list    = qr/${rexp_arg}(?:\s*,\s*${rexp_arg})*/;

# Transform a Gtk class name into an Oz class name
sub gtk2oz_class_name {
    my ($gtk_name) = @_;

    $gtk_name =~ s/^G[dt]k//s;
    return $gtk_name;
}

# Transform a Gtk identifier into an Oz identifier
sub gtk2oz_name {
    my ($gtk_name) = @_;
    my @substrings;
    my $string;

    $gtk_name =~ s/^g[td]k_//is;
    @substrings = split /(\?)|_/, $gtk_name; # We allow '?' in names, ignore them
    foreach $string (@substrings) {
        $string = ucfirst $string;
    }
    $gtk_name = join '', @substrings;

    return $gtk_name;
}

# Transform a Gtk function name into an Oz method name
sub gtk2oz_meth_name {
    my ($gtk_name) = @_;

    # Just use gtk2oz_name and lowercase the first character

    my $name = lcfirst gtk2oz_name($gtk_name);
    return $name unless $$class{name};

    # If we have a class name, check whether this class name
    # is a prefix of our method name. If this is the case,
    # we delete this prefix because it's superfluous.

    my $class_name = gtk2oz_class_name($$class{name});
    $name =~ s/^[a-z]+//s if $name =~ m/^$class_name/is ;
    return lcfirst($name);
}

#sub gtk_class_name_2_function_prefix {
#    my ($class_name) = @_;

#      $class_name =~ s/^Gtk//s;
#      $class_name =~ s/(.)([A-Z])/$1_$2/g;
#      $class_name =~ tr/[A-Z]/[a-z]/;

#      return $class_name;
#  }

sub write_oz_class_header {
#    print "class " . gtk2oz_class_name($$class{name});
    print "X = \nclass \$ ";
    print 'from ' . gtk2oz_class_name($$class{super}) if $$class{super};
    print "\n";
}

sub write_oz_fields_wrappers {
    return unless $$class{fields};

    print "   % Accessors for class fields\n";

    my %fields;
    $fields = $$class{fields};

    foreach my $field (keys %$fields) {
        my $meth = gtk2oz_meth_name("get_$field");
        my $var = gtk2oz_name($field);

        my $native = "$$class{name}\Get". gtk2oz_name($field);
        $native =~ s/^Gtk//s;
        $native = lcfirst $native;

        print '   meth ' . $meth . "(\?$var)\n";
        print '      ' . $var . " = {GtkNative." . $native . " \@nativeObject}\n";
        print "   end\n";
    }

    # TODO: Mutator
}

sub write_oz_init_methods {
    return unless $$class{inits};

    print "   % Init methods for building objects\n";

    my $inits = $$class{inits};

    foreach my $init (keys %$inits) {
        my $in  = $$class{inits}{$init}{in};  # list of input arguments
        my $out = $$class{inits}{$init}{out}; # the output value

        ### Method header

        print '   meth ' . gtk2oz_meth_name($init) . '(';

        ### Method header: Argument list

        {
            my $i = 1;
            map { print ' Arg' . $i++ } @$in;
        }
        print " )\n";

        ### Method invocation

        print '      ';
        print 'nativeObject <- ';
        print '{GtkNative.' . gtk2oz_meth_name($init);

        ### Method invocation: Arguments

        for (my $i = 0; $i < length @$in; $i++) {
            if ($$in[$i] =~ m/^\!/s) {
                print ' {Arg' . ($i+1) . ' getNative($)}';
            } else {
                print ' Arg' . ($i+1);
            }
        }

        print "}\n";

        print "      Object, registerObject\n";
        print "   end\n";
    }
}

sub write_oz_meth_wrappers {
    return unless $$class{meths};

    print "   % Wrappers for methods\n";

    my $meths = $$class{meths};

    foreach my $meth (keys %$meths) {
        my $in  = $$class{meths}{$meth}{in};  # list of input arguments
        my $out = $$class{meths}{$meth}{out}; # the output value

        ### Method header

        print '   meth ' . gtk2oz_meth_name($meth) . '(';

        ### Method header: Argument list

        # TODO: deal rigth with implizid 'self' arguments
        # There are functions, which have no 'self'
        shift @$in; # drop first argument, it's 'self'
        {
            my $i = 1;
            map { print ' Arg' . $i++ } @$in;
        }

        print ' ?Ret' if $out;
        print " )\n";

        ### Method invocation

        print '      ';
        print 'Ret = ' if $out;
        print '{GtkNative.' . gtk2oz_meth_name($meth) . ' @nativeObject';

        ### Method invocation: Arguments

        for (my $i = 0; $i < length @$in; $i++) {
            if ($$in[$i] =~ m/^\!/s) {
                print ' {Arg' . ($i+1) . ' getNative($)}';
            } else {
                print ' Arg' . ($i+1);
            }
        }
        print "}\n";

        print "   end\n";
      }
}

sub process_class {
    print gtk2oz_class_name($$class{name}) . ' = {Value.byNeed proc {$ X} ';

    write_oz_class_header;
    write_oz_fields_wrappers;
    write_oz_init_methods;
    write_oz_meth_wrappers;
    print "end\n"; # class

    print "end\n"; # byNeed
    print '$}'."\n\n";
}

sub build_classes {
    my @files = @_;

    foreach my $file (@files) {
        require $file;
        process_class;
    }
}

sub build_exports {
    my @files = @_;

    foreach my $file (@files) {
        require($file);
        print '   ' . gtk2oz_class_name($$class{name}) . "\n";
    }
}

sub usage() {
    print <<EOF;
usage: $0 INPUT_FILE ...

Generate Oz glue code for the GTK+ binding of Oz

    --oz-classes            build Oz glue code
    --oz-exportlist         build export list for Oz functor

EOF

    exit 0;
}

my ($opt_oz_classes, $opt_oz_exportlist);

&GetOptions("oz-classes"     =>    \$opt_oz_classes,
            "oz-exportlist"  =>    \$opt_oz_exportlist);

@input = @ARGV;

usage() unless @input != 0;
usage() unless $opt_oz_classes | $opt_oz_exportlist;

build_classes(@input) if $opt_oz_classes;
build_exports(@input) if $opt_oz_exportlist;
