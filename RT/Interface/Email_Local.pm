# Adds a ParseReferences function to RT::Interface::Email.
#
# Author: Lars Kellogg-Stedman <lars@oddbit.com>

# {{{ sub ParseReferences

package RT::Interface::Email;

sub ParseReferences {
    my $head = shift;

    # Based on info from <URL:http://www.jwz.org/doc/threading.html>
    my @msgids = ();

    my $references = $head->get('References') || '';
    chomp($references);
    my $inreplyto  = $head->get('In-Reply-To') || '';
    chomp($inreplyto);

    push(@msgids, split(/\s+/, $references)) if ($references);

    if ($inreplyto) {
        if ($inreplyto =~ m/(<[^>]+>)/) {
            push(@msgids, $1);
        } else {
            $RT::Logger->info("Gateway: Unhandled In-Reply-To ".
                               "format: '$inreplyto'");
        }
    }

    # Map Message-id(s) to ticket id
    my %tickets = ();
    my %checked;
    my $ticket = RT::Ticket->new($RT::SystemUser);
    for my $MessageId (@msgids) {
        next if $checked{$MessageId}; # Already looked up this message-id
        my $ticketid = $ticket->LoadByMessageId($MessageId);
        $tickets{$ticketid} = 1 if defined $ticketid;
        $checked{$MessageId} = 1;
    }

    my @ticketids = sort keys %tickets;

    # If the Message-id(s) are already in the database, use their
    # ticked-id
    if (1 < @ticketids) {
        $RT::Logger->debug("Gateway: Several possible tickets: " .
                           join(",", @ticketids) );
    }

    # Just pick the first.  Not sure how we should handle several
    # ticket ids
    return $ticketids[0] if (@ticketids);
}

# }}}

1;

