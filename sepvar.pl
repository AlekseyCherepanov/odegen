#! /usr/bin/perl
# ode task generator, with separable variables: y' = f(x)*g(y)
# генератор уравнений с разделяющимися переменными

# Copyright © 2015 Aleksey Cherepanov <aleksey.4erepanov@gmail.com>
# Redistribution and use in source and binary forms, with or without
# modification, are permitted.

use strict;
use warnings;

use Data::Dumper;

# ** rand($lexems) добавляется к $min_lexems
my $min_lexems = 1;
my $lexems = 3;

# чтобы генерировать мы делаем var, потом заменяем на нужную переменную
my @leafs = (qw/var/ x 10, qw/e pi/ x 2, -10 .. 10);
my @bin_ops = (qw#+ - * /# x 6, "**");
# my @unary_ops = qw/- ln sin sqrt tg arctg cos arcsin arccos ctg arcctg/;
my @unary_ops = qw/- ln sin sqrt cos/;
# my $lexems = 5;
# my @leafs = (qw/x y/, 1, 2);
# my @bin_ops = qw#+ - * /#;
# my @unary_ops = qw/-/;

our $count;

sub gen1 {
    return undef unless $count;
    $count--;
    if (rand(3) >= 1) {
        if (int rand(2)) {
            my $op = @unary_ops[rand($#unary_ops)];
            return [$op, gen1()];
        } else {
            my $op = @bin_ops[rand($#bin_ops)];
            return [$op, gen1(), gen1()];
        }
    } else {
        return undef
    }
}

sub gen {
    local $count = $_[0];
    gen1();
}

# print Dumper gen(10);

sub ser {
    my $a = shift;
    if ($a) {
        my $f = shift @$a;
        my @args = map { ser($_) } @$a;
        if (@args == 2) {
            # %% получается много скобок, правда, их CAS уберёт
            "($args[0]) $f ($args[1])"
        } else {
            "$f($args[0])"
        }
    } else {
        # %% думаю, тут будет слишком много чисел вылезать
        $leafs[rand($#leafs)]
    }
}

# print ser gen(10);

our $dotx;
our $doty;

our %tried;

sub solve {
    ($dotx, $doty) = map { ser gen($_[0]) } 1, 2;
    # $dotx = ser gen($_[0]);
    $dotx =~ s/var/x/g;
    $doty =~ s/var/y/g;
    # print "$dotx ,,, $doty\n";
    $dotx = "($dotx) * ($doty)";
    return "false" if $tried{$dotx};
    $tried{$dotx} = 1;
    # ($dotx, $doty) = ser_simple;
    # такс, вставляем решение ode
    `(echo 'e : %e\$ pi : %pi\$ ln : log\$ arctg : atan\$ display2d : false\$ logexpand : false\$ LINEL : 100000\$'; printf 'ode2('"'"'diff(y, x) = (%s), y, x);\n' '$dotx';) | maxima --very-quiet`;
}

# print solve 10;
# print "y' = $dotx\n";
# die "exited";

my $kk = 0;
my @kk = 0;
my $c = 0;
while ($kk < 100) {

my $s = '';
# $s = 'y = %c*%e^(-%e*x^3/3-%e*x^2/2)';
# $dotx = '((-((x) - (-1))) * (x)) * ((y) * (e))';
my $m = 0;
while ($s eq '' || $s =~ /'integrate/ || $s =~ /\n/ || $s =~ /^false$/ || $dotx !~ /[xy]/ || $dotx !~ /x/ || $dotx !~ /y/) {

    # print "$s || y' = $dotx\n";
    # print "1" if ($s eq '');
    # print "2" if ($s =~ /'integrate/);
    # print "3" if ($s =~ /\n/);
    # print "4" if ($s =~ /^false$/);
    # print "5" if ($dotx !~ /[xy]/);
    # print "7" if ($dotx !~ /x/);
    # print "8" if ($dotx !~ /y/);
    # print "\n";

    # if ($s =~ /^false$/) {
    #     print ">>> $dotx || $s";
    # }
    eval {
        # %% можно было бы использовать hard limit здесь
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 10;
        $s = solve(int rand($lexems) + $min_lexems);
        $s =~ s/^\n//;
        chomp $s;
        # print ">>>> $s <<<<<\n";
    };
    my $problem = $@;
    alarm 0;
    if ($problem eq "timeout\n") {
        warn "timeout: $dotx\n";
        `killall maxima 2>/dev/null`;
    } else {
        if ($problem) {
            # warn "hi there";
            die
        }
    }
    print $c, "\n" if $c++ % 100 == 0;
}

$kk++;

chomp $s;
print "Result: $s || y' = $dotx\n";

}
