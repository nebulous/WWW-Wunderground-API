#!perl

use Test::More tests => 11;

use_ok( 'WWW::Wunderground::API' );

my $wun = new WWW::Wunderground::API('KDCA');
isa_ok($wun,'WWW::Wunderground::API','Got a new Wunderground API object');
$wun->api_type('xml');
$wun->update();
if ($wun->xml) {
  ok(length($wun->xml),'Got XML from wunderground');
} else {
  $wun->raw('<xml version="1.0"><temp_f>50</temp_f></xml>');
  ok(length($wun->xml),'Set test XML');
  $wun->data(Hash::AsObject->new(&XML::Simple::XMLin($wun->xml)));
}
isa_ok($wun->data,'Hash::AsObject','Parsed xml');
like($wun->data->temp_f, qr/\d+/, 'Read temperature of '.$wun->data->temp_f.'f');
is($wun->data->temp_f, $wun->temp_f, "Data key AUTOLOADing");

my $time = $wun->cache->set('test',time);
is($time,$wun->cache->get('test'), 'BadCache "works." But don\'t use it.');

SKIP: {
  my $api_key = $ENV{WUNDERGROUND_KEY} || ''; #Set to your API key for testing
  skip "API tests require WUNDERGROUND_KEY environment variable to be set.", 4 unless $api_key;
  my $wun = new WWW::Wunderground::API(location=>'KDCA', auto_api=>1, api_key=>$api_key);
  isa_ok($wun,'WWW::Wunderground::API','Got a new Wunderground API object');

  like($wun->conditions->temp_f, qr/\d+/, 'Regan National has a temperature: '.$wun->conditions->temp_f.'f');
  ok(length($wun->raw),'raw returns source data');
  isa_ok($wun->data,'Hash::AsObject','Data returns friendly object');
}
