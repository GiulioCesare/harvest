#!/usr/bin/perl
# Argentino 27/03/2020
# Genera identificativi NBN per tesi(/ejounral?) archiviate in wayback machine (memoria)
# arguments through eclipse configuration
#/home/argentino/magazzini_digitali/harvest/tesi/11_nbn/2020_01_26_tesi_sssup_in.url collaudo true test ahToo6uy
#/home/argentino/magazzini_digitali/harvest/tesi/11_nbn/2020_01_26_tesi_sissa.url sviluppo harvest harvest_pwd
#/home/argentino/magazzini_digitali/harvest/e_journals/11_nbn/2020_02_26_ej_unimi.disegni.url sviluppo harvest harvest_pwd riviste.unimi.it/index.php/disegni 1 
#/home/argentino/magazzini_digitali/harvest/e_journals/11_nbn/2020_02_26_ej_unimi.promoitals.url sviluppo harvest harvest_pwd riviste.unimi.it/index.php/promoitals 1 

use strict;
use warnings;
use Encode qw(encode_utf8);
use HTTP::Request ();
use HTTP::Response ();
use JSON;
use LWP::UserAgent;

# =====================================================
# Per far partire il server interno ad eclipse bottone run(>) nbn server (check port)
# -----------------------------------------------------------------------------------
# NMB: Change port according to when starting nbn server (which is dynamic while developing)
# =====================================================

my $header = ['Content-Type' => 'application/json; charset=UTF-8'];
#my $nbn_development = $ENV{NBN_DEVELOPMENT};
my $nbn_server_sviluppo="http://127.0.0.1:5003/api/nbn_generator.pl"; 			# SVILUPPO
my $nbn_server_collaudo="http://nbn-collaudo.depositolegale.it/api/nbn_generator.pl";	# COLLAUDO
#my $nbn_server_collaudo="http://nbn-collaudo.depositolegale.it/arge_api/nbn_generator.pl";	# COLLAUDO ARGE

my $nbn_server_esercizio="http://nbn.depositolegale.it/api/nbn_generator.pl";			# ESERCIZIO
my $nbn_server="";

# Command line parameters
my $url_file="";
my $ambiente="";
my $archived="";
my $arg_username="";
my $arg_password="";
my $arg_opera_per_baseurl="";

my $rows_todo=0; # all by default

# action "nbn_add"				$nbn, $url_memoria, $url_metadata		user:	md, admin
#								INSERT INTO urlrecord (URL, metadataURL, NBNrecordID
#								Url con riferimento a "memoria?"

# action "nbn_create" 			$url, $metadataURL						user:	sito, md
#								INSERT INTO nbnrecord (NBNstatusID, datasourceID)
#								INSERT INTO urlrecord (URL, NBNrecordID) -- si direbbe di
#								INSERT INTO urlrecord (URL, metadataURL, NBNrecordID)

# action "nbn_status_update"	$nbn, $nbn_new_statusName 				user:	sito, admin

sub nbn_create_archived # ()
{
	my ($url_sito, $url_memoria, $url_metadata, $username, $password, $opera_per_baseurl) = @_;


#$username="aoqu-unimi";
#$password="XHTfV$2g";

#$username="gil-unimi";
#$password="gU2AY1Jo";
	
#	# OVERRIDE for specific test
#	$ambiente="collaudo"; 
#	$username="aoqu-unimi";
#	$password="XHTfV$2g";
#	$username="harvest";
#	$password="harvest_pwd";
#	$opera_per_baseurl="riviste.unimi.it/index.php/gilgames";
#	$url_sito="http://riviste.unimi.it/index.php/gilgames/article/view/XXX_7767";
#	$url_memoria="http://memoria.depositolegale.it/*/http://riviste.unimi.it/index.php/gilgames/article/view/XXX_7767";
#	$url_metadata="http://riviste.unimi.it/index.php/gilgames/oai/?verb=GetRecord&metadataPrefix=oai_dc&identifier=oai:ojs.riviste.unimi.it:article/XXX_7767";

	my %data;
#	# Argentino For development only
#	my $nbn_development = $ENV{NBN_DEVELOPMENT};

    # my $user='sssup_user';

	if ($ambiente eq "sviluppo") 
		{
		my $user='harvest';
		$nbn_server = $nbn_server_sviluppo;
        %data = ( 'development_username', $user,	# NMB: OVERRIDE  for DEVELOPMENT
					 'action', 'nbn_create',
					 'url', $url_sito,
					 'metadataURL', $url_metadata,
                     'url_memoria', $url_memoria,
                     'opera_per_baseurl', $opera_per_baseurl);
		}
	else
		{
		if ($ambiente eq "collaudo") 
			{$nbn_server = $nbn_server_collaudo;}
		else
			{$nbn_server = $nbn_server_esercizio;}

		%data = ( 'action', 'nbn_create',
            'url', $url_sito,
            'metadataURL', $url_metadata,
            'url_memoria', $url_memoria,
            'opera_per_baseurl', $opera_per_baseurl);
		}

	my $coder = JSON->new->utf8->pretty->allow_nonref;
	my $js = $coder->encode(\%data);	# convert associative array to json string
	
	
#print "\nnbn_server='".$nbn_server."'";	
	
	my $req = HTTP::Request->new('POST', $nbn_server, $header, $js);
	$req->authorization_basic($username, $password);
	my $ua = LWP::UserAgent->new(); # at this point, we send it via LWP::UserAgent
	my $res = $ua->request($req);

	return $res
} # end nbn_create

sub get_response_body
{
	my ($response) = @_;
	
	if ($ambiente ne "sviluppo") 
		{ # COLLAUDO/ESERCIZIO
#			my $body=$response; 
#			return $body;
			return $response->content;
		}

	# get rid of the header


	my $index = index ($response->content, "\r\n\r\n");
	my $pos=-1;
	if ($index eq -1)
	{
		my $index = index ($response->content, "\n\n");
		if ($index eq -1)
		{
		print "HTTP RESPONSE BODY NOT FOUND\n",$response->content,"\n";
		next; # continue
#		last;
		}
		else
		{
		$pos=$index+4;
		}
	}
	else
	{
		$pos=$index+4;
	}

	my $body=substr($response->content, $pos);
	
	return $body; 
	
} # end get_response_body


# ==============================
# Perl CGI parameters:
# ====================
#	action			nbn_create, nbn_add, nbn_status_update
#	nbn				urn:nbn:it:unibo-32
#	url				http://amsdottorato.cib.unibo.it/9/
#	metadataURL		http://amsdottorato.cib.unibo.it/cgi/oai2?verb=GetRecord&metadataPrefix=oai_dc&identifier=oai:amsdottorato.cib.unibo.it:9


# my $res = nbn_create();
# #print "res=" . $res->as_string;
# if ($res->is_success) {
#     my $message = $res->decoded_content;
#     print "received the message: '".$message."'";
# } else {
#     use Data::Dump qw/ dd /; dd( $res->as_string );
#     print "HTTP get code: ", $res->code, "\n";
#     print "HTTP get msg : ", $res->message, "\n";
# }

# print "\nHello genera_nbn.pl";

# my $numArgs = $#ARGV + 1;
# foreach my $argnum (0 .. $#ARGV)
# {
#   print "\n$ARGV[$argnum]";
# }
# use Data::Dumper qw(Dumper);



# Check parameters in input
die "Usage: $0 url_file nbn_server ambiente username password opera_per_baseurl rows_todo\n" if @ARGV < 6;
$url_file=$ARGV[0];
$ambiente=$ARGV[1];
$arg_username=$ARGV[2];
$arg_password=$ARGV[3];
$arg_opera_per_baseurl=$ARGV[4];
$rows_todo=$archived=$ARGV[5];


#print "\nurl_file=".$url_file;
#print "\nambiente=".$ambiente;
#print "\narchived=".$archived;
#print "\n";


#print "url_file=".$url_file;
open (url_fh, $url_file);
#my $rows_todo=10; # 0 = do all rows
my $rows_done=0;

# Output header
print "\n#OAI Identifier|NBN Identifier|Status Id|Status|Azione";


while (my $record = <url_fh>) {
	last if ($rows_todo != 0 && $rows_done >= $rows_todo); # Facciamo sol oun certo numero di righe o tutte

    # print $record;

    # # my @fields = split /\|/, $record;
    # # print Dumper \@fields;

    # skip empty or commented line
    next if ($record =~/^$/ || substr($record, 0, 1) eq "#");
	my ($oai_identifier, $url_sito, $url_memoria, $url_metadata, $title) = split (/\|/, $record);

#print "\noai_identifier: ".$oai_identifier;
#print "\nurl_sito: ".$url_sito;
#print "\nurl_memoria: ".$url_memoria;
#print "\nurl_metadata: ".$url_metadata;
#print "\ntitle: ".$title;

	my $response = nbn_create_archived ($url_sito, $url_memoria, $url_metadata, $arg_username, $arg_password, $arg_opera_per_baseurl);

#print "\nresponse=" . $response->content;

	my $body = $response->content; #get_response_body ($response);

#print "\nbody=" . $body;

	my $coder = JSON->new->utf8->pretty->allow_nonref;
	my $perl = $coder->decode($body);

#	print "\nOAI:", $oai_identifier;
#	print "\nNBN: ", ${$perl}{ nbn };
#	print "\nAzione: ", ${$perl}{ action };
#	print "\nNBN status : ", ${$perl} { NBNstatusID };
#   print "\nStatus : ", ${$perl} { status };

print "\n".$oai_identifier."|".${$perl}{ nbn }."|".${$perl} { NBNstatusID }."|".${$perl} { status }."|".${$perl}{ action };
#print "\n".$oai_identifier."|".${$perl}{ nbn }."|".${$perl} { status }."|";

#	print "\n";

#	if ($ambiente ne "sviluppo") 
#		{ # COLLAUDO/ESERCIZIO
#		print "\n",${$perl}{ nbn },"|",${$perl} { status },"|", $record;
#		}
#	else
#		{
#		print "\n",${$perl}{ nbn },"|",${$perl}{ action },"|",${$perl} { status },"|", $record;
#		}

#	last; # break

#	}
#	else
#	{
#		print "\nDO - NOT Archived"
#	}

	$rows_done++;

	} # end while

print STDERR "\nElaborate ".$rows_done." righe";
close(url_fh);







__END__
