#!/usr/bin/perl
#
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

use Getopt::Long;

# Regular Expressions
$rexp_type        = qr/\w[\w ]+[\*\[\]]*/;
# We allow '?' as first character of a name to mark return values
$rexp_name        = qr/(?<=\W)\??\w+/;
$rexp_arg         = qr/${rexp_type}\s*${rexp_name}/;
$rexp_arg_list    = qr/${rexp_arg}(\s*,\s*${rexp_arg})*/;

sub gtk2oz_class_name {
    my ($gtk_name) = @_;

    $gtk_name =~ s/^Gtk//s;
    return $gtk_name;
}

sub gtk2oz_name {
    my ($gtk_name) = @_;
    my @substrings;
    my $string;

    $gtk_name =~ s/^gtk_//is;
    @substrings = split /_/, $gtk_name;
    foreach $string (@substrings) {
        $string = ucfirst $string;
    }
    $gtk_name = join '', @substrings;

    return $gtk_name;
}

sub gtk2oz_meth_name {
    my ($gtk_name) = @_;

    return lcfirst(gtk2oz_name($gtk_name));
}

sub gtk_class_name_2_function_prefix {
    my ($class_name) = @_;

    $class_name =~ s/^Gtk//s;
    $class_name =~ s/(.)([A-Z])/$1_$2/g;
    $class_name =~ tr/[A-Z]/[a-z]/;

    return $class_name;
}

sub get_class_name {
    my ($class_string) = @_;

    if($class_string =~ m/class\s+(\w+)\s+/) {
        return $1;
    } else {
        die "Can't find class name in class:\n$class_string";
    }
}

sub get_super_class_name {
    my ($class_string) = @_;

    if($class_string =~ m/class\s+\w+\s+from\s+(\w+)/) {
        return $1;
    } else {
        return "";
    }
}

sub get_fields_list {
    # The field list that's returned is of the following build:
    # ("field_name1", "field_type1", "field_name2", "field_type2" ...)

    my ($class_string) = @_;

    my $rexp_field  = qr/${rexp_name}\s*:\s*${rexp_type}/;
    my $rexp_fields = qr/(${rexp_field}\s+)+/;

    $class_string =~ m/fields\s+(${rexp_fields})/s;
    my $field_string = $1;

    return () unless $field_string;

    $field_string =~ s/\s+$//g;

    my @fields;
    foreach my $i (split /:|\n/, $field_string) {
        $i =~ s/(^\s+)|(\s+$)//g;
        @fields = (@fields, $i);
    }
    return @fields;
}

sub split_argument_string {
    # gets an argument string, eg. 'GtkObject *object' and
    # returns an hash with keys 'name' and 'type'.

    my ($arg_string) = @_;
    my %arg;

    $arg_string =~ m/(${rexp_type})\s*(${rexp_name})/;
    $arg{type} = $1;
    $arg{name} = $2;

    return \%arg;
}

sub get_method_list {
    my ($class_string) = @_;
    my @methods;

    return () unless $class_string =~ m/meth/s;

    my @meths = split 'end\s+', $class_string;
    foreach $meth (@meths) { # remove anoying spaces
        $meths[0] =~ s/^(.*\n)+[ \t]+meth/meth/s;
        $meth =~ s/\s*$//sg;
    }

    foreach $meth (@meths) {
        my %method;
        my @args;

        # method name
        $meth =~ m/meth\s+(${rexp_name})/;
        $method{name} = $+;

        # method arguments
        if ( $meth =~ m/meth\s+${rexp_name}\((${rexp_arg_list})\)/ ) {
            @args = split /\s*,\s*/, $1;
        }
        my @dummy;
        foreach my $arg (@args) {
            @dummy = (@dummy, split_argument_string($arg));
        }
        $method{args} = \@dummy;

        # method return type
        if ( $meth =~ m/meth\s+${rexp_name}\(${rexp_arg_list}\)\s*:\s*(${rexp_type})/ ) {
            $method{return_type} = $+;
        }

        @methods = (@methods, \%method);
    }

    return @methods;
}

sub write_oz_class_header {
    my ($class_name, $super_class_name) = @_;

    print "class"  . gtk2oz_class_name($class_name);
    print " from " . gtk2oz_class_name($super_class_name) if $super_class_name;
    print "\n";
}

sub write_oz_fields_wrappers {
    my ($class_name, @fields) = @_;

    print "   % Accessors for Gtk class fields\n";

    for (my $i = 0; $i < (@fields / 2); $i++) {
        my $field_name = $fields[2 * $i];
        my $field_type = $fields[2 * $i + 1];

        my $oz_class = $class_name;
        $oz_class =~ s/^Gtk//s;
        $oz_class = lcfirst($oz_class);
        my $oz_meth = gtk2oz_meth_name("get_$field_name");
        my $oz_field = gtk2oz_name($field_name);


        # Accessor for this field
        print <<EOF;
   meth $oz_meth(?$oz_field)
      $oz_field = {GtkNative.$oz_class\Get$oz_field \@nativeObject}
   end
EOF

        # Modificator for this field
#       my $oz_meth = lcfirst(gtk2oz_name("set_$field_name"));
#
#       print <<EOF;
#   meth $oz_meth($oz_field)
#      $oz_field = {GtkNative.$oz_class\Set$oz_field \@nativeObject $oz_field}
#   end
#EOF

   }
}

sub is_return_value {
    my ($arg) = @_;

    return ($arg{name} =~ m/^\?/s);
}

sub write_oz_meth_wrappers {
    my ($class_name, @meths) = @_;

    print "   % Wrappers for Gtk class methods\n";

    foreach my $meth (@meths) {
        print "   meth " . gtk2oz_meth_name($$meth{name}) . "(";

        # Arguments
        my @arg = @$meth{args};

        foreach $i (@arg) { print "::: $i{name}\n"; }

        print " ?ReturnValue" if $$meth{return_type};
        foreach my $ret_val (@arg) {
            print " $ret_val{name}" if is_return_value($ret_val);
        }

        print ")\n";

        # Method invocation
        print "      ";
        print "ReturnValue = " if $$meth{return_type};
        print "{GtkNative." . gtk2oz_meth_name($$meth{name}) . "\n";

        print "   end\n";
    }
}

sub process_class {
    my ($class_string) = @_;

    my $class_name       = get_class_name($class_string);
    my $super_class_name = get_super_class_name($class_string);
    #my @args             = get_arg_list($class_string);
    my @fields           = get_fields_list($class_string);
    my @methods          = get_method_list($class_string);

    write_oz_class_header($class_name, $super_class_name);
    write_oz_fields_wrappers($class_name, @fields) if @fields;
    write_oz_meth_wrappers($class_name, @methods)  if @methods;
    print "end\n\n";
}

sub build_classes {
    my @files = @_;
    my $file;
    my $class_string;
    my $depth = 0;

    foreach $file (@files) {
        open(FILE, $file) || die "Could not open file $file. $!";
        while (<FILE>) {
            s/^([^%]*)%.*$/$1/; # ignore comments
            next if m/^\s*$/;   # ignore empty lines

            if(m/meth|class/) { $depth++; }
            if(m/end/)        { $depth--; }

            $class_string = $class_string . $_;

            if($depth == 0) {
                process_class($class_string);
                $class_string = "";
                next;
            }
        }
        die "Parse error in file $file" unless $depth == 0;
        close FILE;
    }
}

sub usage() {
    print <<EOF;
usage: $0 [OPTION] [INPUT FILE] ...

Generate the Oz classes for the GTK+ binding of Oz

EOF

    exit 0;
}

@input = @ARGV;

usage() unless @input != 0;

build_classes(@input);
