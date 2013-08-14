package WWW::Wunderground::API;

use 5.006;
use Any::Moose;
use LWP::Simple;
use XML::Simple;
use JSON::Any;
use Hash::AsObject;

=head1 NAME

WWW::Wunderground::API - Use Weather Underground's XML or JSON interface

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

has api_key => (is=>'ro', isa=>'Str');
has api_type => (is=>'rw', default=>sub {$_[0]->api_key ? 'json' : 'xml'});
has location => (is=>'rw', required=>1, trigger=>\&update);
has xml => (is=>'rw', isa=>'Str');
has json => (is=>'rw', isa=>'Str');
has data => (is=>'rw',isa=>'Hash::AsObject');



sub update {
  my $self = shift;
  if ($self->api_type eq 'json') {
    my $json = get('http://api.wunderground.com/api/'.$self->api_key.'/conditions/q/'.$self->location.'.json');
    if ($json) {
      $self->json($json);
      $self->data(Hash::AsObject->new(JSON::Any->jsonToObj($json)->{current_observation})); 
    }
  } else {
    my $xml = get('http://api.wunderground.com/auto/wui/geo/WXCurrentObXML/index.xml?query='.$self->location);
    if ($xml) {
      $self->xml($xml);
      $self->data(Hash::AsObject->new(XMLin($xml)));
    }
  }
}

sub api_call {
	my $self = shift;
	my ($action, $location) = @_;
	if ($self->api_key) {
		my $base = 'http://api.wunderground.com/api';
		my $url = join('/', $base,$self->api_key,$action,$location).'.json';
		warn "CALLING $url\n\n";
		#my $json = get($url);
	} else {
		warn "Only basic weather conditions are supported using the XML interface";
	}
}

around BUILDARGS => sub {
  my $orig = shift;
  my $class = shift;
  if (@_ == 1 and !ref($_[0])) {
    return $class->$orig( location=>$_[0] );
  } else {
    return $class->$orig(@_);
  }
};

sub AUTOLOAD {
  my $self = shift;
  our $AUTOLOAD;
  my ($key) = $AUTOLOAD =~ /::(\w+)$/;
  my $val = $self->data->$key;
  if (defined($val)) {
    return $val;
  } else {
    warn "$key is not defined. Is it a valid key, and is data actually loading?";
    return undef;
  }
}

#no Any::Moose;


=head1 SYNOPSIS

Connects to the Weather Underground JSON/XML service and parses the data
into something usable. The entire response is available in Hash::AsObject form, so
any data that comes from the server is accessible. Print a Data::Dumper of ->data
to see all of the tasty data bits.

    use WWW::Wunderground::API;

    #location
    my $wun = new WWW::Wunderground::API('Fairfax, VA');

    #or zipcode
    my $wun = new WWW::Wunderground::API('22030');

    #or airport identifier
    my $wun = new WWW::Wunderground::API('KIAD');

    #using the json API.
    my $wun = new WWW::Wunderground::API(location=>'KIAD', api_key=>'your wunderground API key');

    print 'The temperature is: '.$wun->data->temp_f."\n";
    print 'The rest of the world calls that: '.$wun->temp_c."\n"; #Keys are AUTOLOADed to $wun->data->$key for lazy typers.
    print 'XML source:'.$wun->xml if $wun->api_type eq 'xml';
    print 'JSON source:'.$wun->json if $wun->api_type eq 'json';


=head2 update()

Refetch data from the server. This is called automatically every time location is set, but you may want to put it in a timer.

=head2 location()

Change the location. For example:

    my $wun = new WWW::Wunderground::API('22030');
    my $ffx_temp = $wun->data->temp_f;

    $wun->location('KJFK');
    my $ny_temp = $wun->data->temp_f;

    $wun->location('San Diego, CA');
    my $socal_temp = $wun->data->temp_f;

=head2 xml()

Returns raw xml result from wunderground server where applicable

=head2 json()

Returns raw json result from wunderground server where applicable

=head2 data()

Contains all weather data from server parsed into convenient Hash::AsObject form;

=head2 api_key()

Required for JSON api access.

=head2 api_type()

Defaults to xml. If an api_key is specified, this will be set to json.

=head1 AUTHOR

John Lifsey, C<< <nebulous at crashed.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-wunderground-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Wunderground-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Wunderground::API


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Wunderground-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Wunderground-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Wunderground-API>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Wunderground-API/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2011 John Lifsey.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

__PACKAGE__->meta->make_immutable;
1; # End of WWW::Wunderground::API
