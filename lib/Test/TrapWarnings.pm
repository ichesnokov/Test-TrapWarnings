use 5.008;

package Test::TrapWarnings;

use strict;
use warnings;
use Test::More;

our $VERSION = '0.01';

use Exporter;
use parent 'Exporter';
our @EXPORT_OK = qw(trap_warning trap_warnings no_warnings);
our @EXPORT    = @EXPORT_OK;

=head1 NAME

Test::TrapWarnings - trap warnings and check their contents while testing other
code.

=head1 SYNOPSIS

    use Some::Module;
    use Test::More;
    use Test::TrapWarnings;
    
    my $code_result = trap_warning(
        Some::Module::some_func(@args),
        qr/at \s+ line/x,
        q{some_func() emitted a warning that was expected}
    );
    is($code_result, $expected_value, 'some_func() returned a proper value');

=head1 DESCRIPTION

Sometimes when you test a certain code you want to check whether this code
emits (or doesn't emit) any warnings, and if so, check the content of these
warnings. When you're using modules like L<Test::Warn> or L<Test::NoWarning>,
you need to call your code 2 times: one for testing its warnings, another to
test return values.

Functions of this module allow you to do that by calling your code only once
because its functions return the same results as your code returns - whether in
scalar or list context.

In other words this module is similar to L<Test::Trap> by its functionality,
but is more simple and only targeted to trapping warnings.

=head1 FUNCTIONS

All functions of this module are exported by default.

=head3 trap_warning

Checks that the warning emitted by the code matches regexp and returns result
of the called code in proper context.

 In: $code - subroutine reference that will be executed
 In: $regexp - regexp to which the warning is matched
 In: $message - (optional) message to display to the user
 Out: the same results as the passed coderef returns

=cut

sub trap_warning(&$;$) {
    my ($code, $regexp, $message) = @_;

    $message ||= 'Warning matched';

    my $caught_warnings;
    local $SIG{__WARN__} = sub {
        $caught_warnings++;
        like($_[0], $regexp, $message);
    };
    my (@results, $result);
    if (wantarray) {
        @results = $code->();
    } else {
        $result = $code->();
    }

    note "caught $caught_warnings warning(s)";

    fail("$message (no warnings caught)") if !$caught_warnings;
    return wantarray ? @results : $result;
}

=head3 trap_warnings

The same as C<trap_warning>, but traps several warnings at once (and fails if
the number of warnings emitted is different from the expected number).

 In: $code - subroutine reference that will be executed
 In: $regexps - arrayref of regexps to which the warning is matched
 In: $messages - arrayref of messages to display when each corresponding warning
     matches regexp (or not). Messages are optional.
 Out: the same results as the passed coderef returns

=cut

sub trap_warnings(&$;$) {
    my ($code, $regexps, $messages) = @_;

    my @warnings;
    local $SIG{__WARN__} = sub {
        push @warnings, $_[0];
    };
    my (@results, $result);
    if (wantarray) {
        @results = $code->();
    } else {
        $result = $code->();
    }

    if (scalar @warnings != scalar @$regexps) {
        fail('Caught ' . scalar(@warnings)
            . ' warnings, but got ' . scalar(@$regexps)
            . ' regular expressions to check');
    } else {
        for my $i (0 .. $#warnings) {
            my $message
                = ref $messages eq 'ARRAY' && $messages->[$i] ? $messages->[$i]
                : $messages && !ref $messages                 ? $messages
                : "Warning $i matched";
            like($warnings[$i], $regexps->[$i], $message);
        }
    }

    return wantarray ? @results : $result;
}

=head3 no_warnings

Check that the code we're calling does not emit any warnings.

 In: $code
 In: $message (optional)
 Out: the same results as the passed coderef returns

=cut

sub no_warnings (&;$) {
    my ($code, $message) = @_;

    my @warnings;
    local $SIG{__WARN__} = sub {
        warn $_[0];
        push @warnings, $_[0];
    };
    my (@results, $result);
    if (wantarray) {
        @results = $code->();
    } else {
        $result = $code->();
    }

    $message ||= 'Code does not emit warnings';
    if (my $count_warnings = scalar @warnings) {
        fail("$message: caught $count_warnings warnings");
    } else {
        pass($message);
    }
    ok(!scalar @warnings, $message);

    return wantarray ? @results : $result;
}

=head1 AUTHOR

Ilya Chesnokov L<chesnokov@cpan.org>

=head1 SEE ALSO

L<Test::Warn>, L<Test::NoWarning>, L<Test::Trap>.

=head1 LICENSE

Under the same terms as Perl itself.

=cut

1;
