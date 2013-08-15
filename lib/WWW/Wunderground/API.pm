package WWW::Wunderground::API;

use 5.006;
use Moo;
use LWP::Simple;
use XML::Simple;
use JSON::Any;
use Hash::AsObject;

=head1 NAME

WWW::Wunderground::API - Use Weather Underground's XML or JSON interface

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

has location => (is=>'rw', required=>1);
has api_key => (is=>'ro');
has api_type => (is=>'rw', default=>'json');
has cache => (is=>'ro', lazy=>1, default=>sub { new WWW::Wunderground::API::BadCache });
has auto_api => (is=>'ro', default=>0 );
has raw => (is=>'rw', default=>'');
has data => (is=>'rw', lazy=>1, default=>sub{ Hash::AsObject->new } );

sub json {
  my $self = shift;
  return $self->api_type eq 'json' ? $self->raw : undef;
}

sub xml {
  my $self = shift;
  return $self->api_type eq 'xml' ? $self->raw : undef;
}


sub update {
  my $self = shift;
  if ($self->api_key) {
    $self->api_call('conditions'); 
  } else {
    my $xml = get('http://api.wunderground.com/auto/wui/geo/WXCurrentObXML/index.xml?query='.$self->location);
    if ($xml) {
      $self->xml($xml);
      $self->data(Hash::AsObject->new(XMLin($xml)));
    }
  }
}

sub guess_key {
	my $self = shift;
	my ($struc,$action) = @_;

	#try to guess result structure key
	return $action if defined($struc->{$action});
	foreach my $key (keys %$struc) {
		next if $key=~ /(response|features|version|termsofservice)/i;
		return $key;
	}
}

sub api_call {
	my $self = shift;
	my ($action, $location) = @_;
	$location||=$self->location;
	if ($self->api_key) {
		my $base = 'http://api.wunderground.com/api';
		my $url = join('/', $base,$self->api_key,$action,'q',$location).'.'.$self->api_type;

    my $result;
    unless ($result = $self->cache->get($url)) {
      $result = get($url);
      $self->cache->set($url,$result);
    }

    $self->raw($result);
 
		my $struc = $self->api_type eq 'json'
			? JSON::Any->jsonToObj($self->raw)
			: XMLin($self->raw);

		my $action_key = $self->guess_key($struc,$action);

    $struc = $struc->{$action_key} if $action_key;
    $self->data->{$action} = $struc;

    return new Hash::AsObject($struc);
	} else {
		warn "Only basic weather conditions are supported using the deprecated keyless interface";
		warn "please visit http://www.wunderground.com/weather/api to obtain your own API key";
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
    return $self->api_call($key) if $self->auto_api;
    warn "$key is not defined. Is it a valid key, and is data actually loading?";
    warn "If you're trying to autoload an endpoint, set auto_api to something truthy";
    return undef;
  }
}

sub DESTROY {}

__PACKAGE__->meta->make_immutable;


#The following exists purely as an example for others of what not to do.
#Use a Cache::Cache or CLI Cache. Really.
package WWW::Wunderground::API::BadCache;
use Moo;

has store=>(is=>'rw', lazy=>1, default=>sub{{}});

sub get {
  my $self = shift;
  my ($key) = @_;
  if (exists($self->store->{$key})) {
    return $self->store->{$key};
  }
  return undef;
}

sub set {
  my $self = shift;
  my ($key, $val) = @_;
  $self->store->{$key} = $val;
  return $val;
}


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

    #using the options

    my $wun = new WWW::Wunderground::API(
      location=>'22152',
      api_key=>'my wunderground api key',
      auto_api=>1,
      cache=>Cache::FileCache->new({ namespace=>'wundercache', default_expires_in=>2400 }) #A cache is probably a good idea. 
    );

    
    #Check the wunderground docs for details, but here are just a few examples 
    print 'The temperature is: '.$wun->conditions->temp_f."\n"; 
    print 'The rest of the world calls that: '.$wun->conditions->temp_c."\n"; 
    print 'Record high temperature year: '.$wun->almanac->temp_high->recordyear."\n";
    print "Sunrise at:".$wun->astronomy->sunrise->hour.':'.$wun->astronomy->sunrise->minute."\n";
    print "Simple forecast:".$wun->forecast->simpleforecast->forecastday->[0]{conditions}."\n";
    print "Text forecast:".$wun->forecast->txt_forecast->forecastday->[0]{fcttext}."\n";
    print "Long range forecast:".$wun->forecast10day->txt_forecast->forecastday->[9]{fcttext}."\n";
    print "Chance of rain three hours from now:".$wun->hourly->[3]{pop}."%\n";
    print "Nearest airport:".$wun->geolookup->nearby_weather_stations->airport->{station}[0]{icao}."\n";


=head2 update()

Included for backward compatibility only.
Refetches conditions data from the server. It will be removed in a future release.
If you specify an api_key then this is equvilent of ->api_call('conditions')

=head2 location()

Change the location. For example:

    my $wun = new WWW::Wunderground::API('22030');
    my $ffx_temp = $wun->data->temp_f;

    $wun->location('KJFK');
    my $ny_temp = $wun->data->temp_f;

    $wun->location('San Diego, CA');
    my $socal_temp = $wun->data->temp_f;

=head_2 auto_api

set auto_api to something truthy to have the module automatically make API calls without the use of api_call()

=head_2 api_call( api_name, location )

set api_name to any location-based wunderground api call (eg almanac,conditions,forecast,history...)
set location to any valid location (eg 22152,'KIAD','q/CA/SanFrancisco',...)


=head2 raw()

Returns raw text result from the most recent API call. This will be either xml or json depending on api_type

=head2 xml()

*Deprecated* - use raw() instead
Returns raw xml result from wunderground server where applicable

*Deprecated* - use raw() instead
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

Better yet, fork on github and send me a pull request:
L<https://github.com/nebulous/WWW-Wunderground-API>



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
