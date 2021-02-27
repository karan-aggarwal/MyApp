package MyApp::Controller::Books;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

MyApp::Controller::Books - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched MyApp::Controller::Books in Books.');
}

=head2 list

=cut

sub list :Local {
    my ( $self, $c ) = @_;

    $c->stash(books => [$c->model('DB::Book')->all]);
    $c->stash(template => 'books/list.tt2')
}

=head2 base

=cut

sub base :Chained('/') :PathPart('books') :CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash( resultset => $c->model('DB::Book') );
    $c->log->debug('*** INSIDE BASE METHOD ***');
}

=head2 url_create

Create a book with the supplied title, rating and author

=cut

sub url_create :Chained('base') :PathPart('url_create') :Args(3) {
    my ( $self, $c, $title, $rating, $author_id ) = @_;

    # Call create on the Book model object
    my $book = $c->model('DB::Book')->create(
        {
            title  => $title,
            rating => $rating
        }
    );

    # Add a record to the join table for this book, mapping to appropriate author
    $book->add_to_book_authors( { author_id => $author_id } );

    # Assign the book object to the stash and set template
    $c->stash( book => $book, template => 'books/create_done.tt2' );

    # Disable caching for this page
    $c->response->header( 'Cache-Control' => 'no-cache' );
}

=head2 form_create

Display form to collect information for book to create

=cut

sub form_create :Chained('base') :PathPart('form_create') :Args(0) {
    my ( $self, $c ) = @_;

    # Set the TT template to use
    $c->stash( template => 'books/form_create.tt2' );
}

=head2 form_create_do

Take information from form and add to database

=cut

sub form_create_do :Chained('base') :PathPart('form_create_do') : Args(0) {
    my ( $self, $c ) = @_;

    # Retrieve the values from the form
    my $title     = $c->request->params->{title}     || 'N/A';
    my $rating    = $c->request->params->{rating}    || 'N/A';
    my $author_id = $c->request->params->{author_id} || '1';

    # Create the book
    my $book = $c->model('DB::Book')->create(
        {
            title  => $title,
            rating => $rating
        }
    );

    # Handle relationship with author
    $book->add_to_book_authors( { author_id => $author_id } );

    $c->stash( book => $book, template => 'books/create_done.tt2' );
}

=head2 object

Fetch the specified book object based on the book ID and store it in the stash

=cut

sub object :Chained('base') :PathPart('id') :CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    $c->stash( object => $c->stash->{resultset}->find($id) );

    die "Book $id not found!" if !$c->stash->{object};

    $c->log->debug("*** INSIDE OBJECT METHOD for obj id=$id ***");
}

=head2 delete

=cut

sub delete :Chained('object') :PathPart('delete') :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{object}->delete;

    # Redirect the user back to list page with status msg as an arg
    $c->response->redirect(
        $c->uri_for( $self->action_for('list'), { status_msg => 'Book deleted' } )
    );
}

=head2 list_recent

List recently created books

=cut

sub list_recent :Chained('base') :PathPart('list_recent') :Args(1) {
    my ( $self, $c, $mins ) = @_;

    $c->stash(
        books => [
            $c->model('DB::Book')
              ->created_after( DateTime->now->subtract( minutes => $mins ) )
        ]
    );

    $c->stash( template => 'books/list.tt2' );
}

=head2 list_recent_tcp

List recently created books

=cut

sub list_recent_tcp :Chained('base') :PathPart('list_recent_tcp') :Args(1) {
    my ( $self, $c, $mins ) = @_;

    $c->stash(
        books => [
            $c->model('DB::Book')
              ->created_after( DateTime->now->subtract( minutes => $mins ) )
              ->title_like('TCP' )
        ]
    );

    $c->stash( template => 'books/list.tt2' );
}

=encoding utf8

=head1 AUTHOR

Karan Aggarwal

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
