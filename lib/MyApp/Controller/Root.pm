package MyApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=encoding utf-8

=head1 NAME

MyApp::Controller::Root - Root Controller for MyApp

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # Hello World
    $c->response->body( $c->welcome_message );
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head2 auto

Checks if there is a user and, if not, forward to login page

=cut

sub auto : Private {
    my ( $self, $c ) = @_;

    if ( $c->controller eq $c->controller('Login') ) {
        return 1;
    }
    if ( !$c->user_exists ) {
        # Dump a log message to the development server debug output
        $c->log->debug("***Root::auto User not found, forwarding to /login");
        # Redirect the user to the login page
        $c->response->redirect( $c->uri_for('/login') );
        # Return 0 to cancel 'post-auto' processing and prevent use of application
        return 0;
    }

    return 1;
}

=head1 AUTHOR

Karan Aggarwal

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
