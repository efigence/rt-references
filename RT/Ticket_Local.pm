# Adds a LoadByMessageId function to RT::Ticket.
#
# Author: Lars Kellogg-Stedman <lars@oddbit.com>

# {{{ sub LoadByMessageId

=head2 LoadByMessageId

Given a RFC 822 message id, loads the specified ticket.  If the
message id is assosiated with several tickets, select the smallest
ticket id.

=cut

sub LoadByMessageId {
    my $self = shift;
    my $MessageId = shift;

    if ($MessageId =~ m/<([^>]+)>/) {
        $MessageId = $1;
    }

    my $Attachs = RT::Attachments->new($RT::SystemUser);
    $Attachs->Limit( FIELD => 'MessageId',
                     OPERATOR => '=',
                     VALUE => $MessageId
                     );
    $Attachs->Limit( FIELD => 'Parent',
                     OPERATOR => '=',
                     VALUE => '0'
                     );
    my $trs = $Attachs->NewAlias('Transactions');
    my $tis = $Attachs->NewAlias('Tickets');
    $Attachs->Join( ALIAS1 => 'main',
                    FIELD1 => 'TransactionId',
                    ALIAS2 => $trs,
                    FIELD2 => 'id'
                    );
    $Attachs->Join( ALIAS1 => $trs,
                    FIELD1 => 'ObjectID',
                    ALIAS2 => $tis,
                    FIELD2 => 'id'
                    );
    $Attachs->Limit( ALIAS => $trs,
                     FIELD => "objecttype",
                     OPERATOR => '=',
                     VALUE => 'RT::Ticket'
                     );
    my %tickets = ();
    while (my $attachment = $Attachs->Next) {
        $tickets{$attachment->TransactionObj()->Ticket} = 1;
    }
    my @ids = sort { $a <=> $b } keys %tickets;
    if (1 < @ids) {
        $RT::Logger->info("Message ID $MessageId maps to several tickets.",
                          "Selecting the first.");
    }
    if (@ids) {
        return $self->Load($ids[0]);
    } else {
        return undef;
    }
}

# }}}

1;

