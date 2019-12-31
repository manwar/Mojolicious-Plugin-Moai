
=head1 DESCRIPTION

This tests the L<Test::Mojo::Role::Moai> test role. All the templates with sample
data are in the C<__DATA__> section of this file.

=cut

use Mojo::Base -strict;
use Test2::API qw( intercept );
use Test::More;
use Test::Mojo;
use Mojolicious;
use List::Util qw( first );

sub check_test {
    my ( $test, %param ) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $events = intercept { $test->() };
    # We will get at least 1 event, the Ok event. If the test fails, we
    # will get at least 3 events: The Ok event (a failure), a diag event
    # with stack information (generated by Test::More), and a diag event
    # with additional diagnostics (generated by Test::Mojo::Role::Moai)
    my $event = first { $_->isa( 'Test2::Event::Ok' ) } reverse @$events;
    is $event->pass, $param{ ok }, $param{name} . ': pass/fail is correct';
    if ( my $diag = $param{ diag } ) {
        my $event = $events->[-1];
        if ( !$event ) {
            fail $param{name} . ': No diag message found';
        }
        elsif ( ref $diag eq 'Regexp' ) {
            like $event->message, $diag, $param{name} . ': diag message matches';
        }
        else {
            is $event->message, $diag, $param{name} . ': diag message equals';
        }
    }
}

subtest 'table' => sub {
    subtest 'table_is - Complete equality' => sub {
        my $app = Mojolicious->new;
        $app->routes->get( '/' )->name( 'table_is' );
        my $t = Test::Mojo->with_roles( '+Moai' )->new( $app );

        check_test(
            sub {
                $t->get_ok( '/' )->table_is(
                    'table#mytable',
                    [
                        [ preaction => 'doug@example.com' ],
                        [ inara => 'cat@example.com' ],
                    ],
                    'table_is with ordered arrays (pass)',
                );
            },
            name => 'table_is with ordered arrays (pass)',
            ok => 1,
        );
        ok $t->success, 'Test::Mojo success flag is set to true';

        check_test(
            sub {
                $t->get_ok( '/' )->table_is(
                    'table#mytable',
                    [
                        [ preaction => 'doug@example.com' ],
                        [ inara => 'dog@example.com' ],
                    ],
                    'table_is with ordered arrays (fail)',
                );
            },
            ok => 0,
            name => 'table_is with ordered arrays (fail)',
            diag => qr{Row: 2 - Col: 2\nExpected: "dog\@example\.com"\nGot: "cat\@example\.com"},
        );
        ok !$t->success, 'Test::Mojo success flag is set to false';


    };
};

done_testing;

__DATA__
@@ table_is.html.ep
<table id="mytable">
    <thead>
        <tr>
            <th>User</th>
            <th>E-mail</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>preaction</td>
            <td><a href="mailto:doug@example.com">doug@example.com</a></td>
        </tr>
        <tr>
            <td>inara</td>
            <td><a href="mailto:cat@example.com">cat@example.com</a></td>
        </tr>
    </tbody>
</table>
