#!/usr/bin/perl
use strict;
use Data::Dumper;

use Encode;
use lib '/root/software/OvhApi-perl-1.1';
use OvhApi;
require JSON;
binmode STDOUT, ':utf8';
require utf8;

# [DEMO] - root :~ # apt-get install libjson-any-perl libjson-perl libdigest-sha-perl libcrypt-util-perl
# https://api.ovh.com/createToken/

ovhApi('action'=> $ARGV[0] );  # example : getDatacenter
exit;

sub ovhApi
{
    my (%params) = @_;

    my $action = $params{'action'};

    if(not $action)
    {
        die('Missing action');
    }

    my $context         = getContext();

    my $AK              = $context->{'AK'};                     # Put here your application key
    my $AS              = $context->{'AS'};                     # Put here your  application secret
    my $CK              = $context->{'CK'};                     # Put here your consumer key
    my $serviceName     = $context->{'serviceName'};
    my $datacenterId    = $context->{'datacenterId'};
    my $name            = $context->{'profileFilerName'};

    my $Api = OvhApi->new(
        type                => OvhApi::OVH_API_EU,
        applicationKey      => $AK,
        applicationSecret   => $AS,
        consumerKey         => $CK
    );

    my $urls = {
        'getDatacenter' => { 
            path        => "/dedicatedCloud/$serviceName/datacenter/$datacenterId",
            methodApi   => 'get',
        },
        'orderFiler'    => {
            path        => "/dedicatedCloud/$serviceName/datacenter/$datacenterId/orderNewFilerHourly",
            body        => { name =>  $name },
            methodApi   => 'post',
        },
    };

    my $methodApi =  $urls->{$action}->{'methodApi'};

    my $apiParams = $urls->{$action};
    delete $apiParams->{'methodApi'};

    my $Answer = $Api->$methodApi(
        %{$apiParams},
    );

    my $jsonResponse = $Answer->{'response'}->{'_content'};
    if(not $jsonResponse)
    {
        print "Not content on response\n";
        exit;
    }
    my $hashResponse = '';
    eval {
        $hashResponse = JSON::decode_json($jsonResponse);
    };
    if($@)
    {
        print Dumper $Answer->{'response'}->{'_content'};
    }

    if(ref $hashResponse eq 'HASH')
    {
        while (my ($key , $value ) = each %$hashResponse)
        {
            print "$key : $value\n";
        }
    }
    else
    {
        print Dumper $hashResponse;
    }
    exit;

}

sub getContext
{
    my $result = '';
    my $ret = open(OUTPUT, "cat /root/scripts/.context |");
    if(not $ret)
    {
        die("Cannot open pipe", $!);
    }
    else
    {
        while(my $res = <OUTPUT>)
        {
            $result .= $res;
        }
        close OUTPUT;
    }

    my $hashContext = JSON::decode_json($result);

    if(ref $hashContext ne 'HASH')
    {
        die('Error on decode_json');
    }
    return $hashContext;
}
