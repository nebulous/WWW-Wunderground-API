#!perl

use Test::More tests => 10;

use_ok( 'WWW::Wunderground::API' );

my $wun = new WWW::Wunderground::API('KDCA');
isa_ok($wun,'WWW::Wunderground::API','Got a new Wunderground API object');
if ($wun->xml) {
  ok(length($wun->xml),'Got XML from wunderground');
} else {
  $wun->xml('<xml version="1.0"><temp_f>50</temp_f></xml>');
  ok(length($wun->xml),'Set test XML');
  $wun->data(Hash::AsObject->new(&XML::Simple::XMLin($wun->xml)));
}
isa_ok($wun->data,'Hash::AsObject','Parsed xml');
like($wun->data->temp_f, qr/\d+/, 'Read temperature of '.$wun->data->temp_f.'f');
is($wun->data->temp_f, $wun->temp_f, "Data key AUTOLOADing");

SKIP: {
  my $api_key = ''; #Set to your API key for testing
  skip "JSON tests require an API key to be specified.", 4 unless $api_key;
  my $wun = new WWW::Wunderground::API(location=>'KDCA', api_key=>$api_key);
  isa_ok($wun,'WWW::Wunderground::API','Got a new Wunderground API object');
  ok(length($wun->json),'Got JSON from wunderground');
  isa_ok($wun->data,'Hash::AsObject','Parsed json');
  like($wun->data->temp_f, qr/\d+/, 'Read temperature of '.$wun->data->temp_f.'f');
}
