#!/usr/bin/env perl
use strict;
use warnings;
use XML::Simple;
use WWW::Curl::Easy;
use JSON::PP qw(encode_json decode_json);
use Data::Dumper;

# Update the `publications.xml` database, adding in any new data (updated NASA ADS bibcodes, DOIs, etc.), and ensurnig that tags
# in the Galacticus repo are also updated.
# Andrew Benson (30-May-2025)

# Read arguments.
die("Usage: updatePublications.pl <apiToken> <slackURL> <repoPath>")
    unless ( scalar(@ARGV) == 3 );
my $apiToken = $ARGV[0];
my $slackURL = $ARGV[1];
my $repoPath = $ARGV[2];

# Extract all tags from the repo.
my %tags;
open(my $git,"git --git-dir ".$repoPath."/.git tag -l |");
while ( my $tag = <$git> ) {
    chomp($tag);
    $tags{$tag} = 0;
}
close($git);

# Parse the database.
my $xml          = new XML::Simple();
my $publications = $xml->XMLin("publications.xml");

# Extract/construct current bibcodes.
print "Searching for bibcodes in database...\n";
my %bibCodes;
foreach my $publication ( @{$publications->{'publication'}} ) {
    my $bibCode;
    if      ( exists($publication->{'bibCode'}) ) {
	# Use the NASA ADS bibcode directly.
	$bibCode = $publication->{'bibCode'};
    } elsif ( exists($publication->{'arXiv'  }) ) {
	# Construct a bibcode from the arXiv number.
	(my $arXivReduced = $publication->{'arXiv'}) =~ s/\.//;
	$bibCode = $publication->{'year'}."arXiv".$arXivReduced.substr($publication->{'author'},1,1);
    }
    # Store a reference to this publication in our bibcodes dictionary.
    if ( defined($bibCode) ) {
	$bibCodes{$bibCode}->{'entry'} = $publication;
	print "   found bibcode: ".$bibCode."\n";
    } else {
	print Dumper($publication);
	die("no bibcode available for this entry");
    }
}
print("...done\n");

# Pull records from NASA ADS.
## Construct a curl object.
my $curl = WWW::Curl::Easy->new();
$curl->setopt(CURLOPT_HEADER,1);
$curl->setopt(CURLOPT_HTTPHEADER, ['Authorization: Bearer '.$apiToken,"Content-Type: big-query/csv"]);
my $countRecords = scalar(keys(%bibCodes));
$curl->setopt(CURLOPT_URL, 'https://api.adsabs.harvard.edu/v1/search/bigquery?q=*:*&rows='.$countRecords.'&fl=bibcode,alternate_bibcode,doi,title,author,year,pub,volume,page');
my $response_body;
$curl->setopt(CURLOPT_WRITEDATA,\$response_body);
$curl->setopt(CURLOPT_POST, 1);
$curl->setopt(CURLOPT_POSTFIELDS, "bibcode\n".join("\n",sort(keys(%bibCodes))));
my $retcode = $curl->perform;
my $records;
if ($retcode == 0) {
    my $response_code = $curl->getinfo(CURLINFO_HTTP_CODE);
    if ( $response_code == 200 ) {
	# Extract the JSON.
	my $json;
	my $startFound = 0;
	open(my $response,"<",\$response_body);
	while ( my $line = <$response> ) {
	    $startFound = 1
		if ( $line =~ m/^\{/ );
	    $json .= $line
		if ( $startFound );
	}
	close($response);
	$records = decode_json($json);
    } else {
	die("Failed to retrieve record identifiers: ".$response_code.$response_body."\n");
    }
} else {
    die("Failed to retrieve record identifiers: ".$retcode." ".$curl->strerror($retcode)." ".$curl->errbuf."\n");
}

# Match records with our entries.
print "Matching NASA ADS bibcodes to entries...\n";
foreach my $record ( @{$records->{'response'}->{'docs'}} ) {
    my $matchedBibCode;
    if ( exists($bibCodes{$record->{'bibcode'}}) ) {
	$matchedBibCode = $record->{'bibcode'};
    } elsif ( exists($record->{'alternate_bibcode'}) ) {
	foreach my $altBibCode ( @{$record->{'alternate_bibcode'}} ) {
	    if ( exists($bibCodes{$altBibCode}) ) {
		$matchedBibCode = $altBibCode;
	    }
	}
    }
    if ( defined($matchedBibCode) ) {
	$bibCodes{$matchedBibCode}->{'record'} = $record;
	print "   matched record for bibcode: ".$matchedBibCode."\n";
    } else {
	die("unable to match record (bibcode: ".$record->{'bibcode'}.") to entry");
    }
}
print "...done\n";

# Process each entry and apply updates.
print "Checking for updates...\n";
my @newTags;
foreach my $bibCode ( keys(%bibCodes) ) {
    # Replace the bibcode with the canonical bibcode.
    if ( $bibCodes{$bibCode}->{'record'}->{'bibcode'} ne $bibCodes{$bibCode}->{'entry'}->{'bibCode'} ) {
	print "   update bibcode to canonical value: ".$bibCodes{$bibCode}->{'entry'}->{'bibCode'}." --> ".$bibCodes{$bibCode}->{'record'}->{'bibcode'}."\n";
	$bibCodes{$bibCode}->{'entry'}->{'bibCode'} = $bibCodes{$bibCode}->{'record'}->{'bibcode'};
    }
    # Add DOI if necessary.
    foreach my $doi ( @{$bibCodes{$bibCode}->{'record'}->{'doi'}} ) {
	next
	    if ( $doi =~ m/arXiv/ );
	if ( $doi ne $bibCodes{$bibCode}->{'entry'}->{'doi'} ) {
	    $bibCodes{$bibCode}->{'entry'}->{'doi'} = $doi;
	    print "   update doi for bibcode ".$bibCodes{$bibCode}->{'entry'}->{'bibCode'}." to: ".$doi."\n";
	}
	last;
    }
    # Add journal URL if necessary.
    if ( exists($bibCodes{$bibCode}->{'entry'}->{'doi'}) ) {
	my $curl = WWW::Curl::Easy->new();
	$curl->setopt(CURLOPT_URL, 'https://doi.org/'.$bibCodes{$bibCode}->{'entry'}->{'doi'});
	my $response_body;
	$curl->setopt(CURLOPT_WRITEDATA,\$response_body);
	my $retcode = $curl->perform;
	if ($retcode == 0) {
	    my $journalURL;
	    open(my $response,"<",\$response_body);
	    while ( my $line = <$response> ) {
		if ( $line =~ m/href="(.+)"/ ) {
		    my $url = $1;
		    $journalURL = $url
			unless ( $url =~ m/arxiv/i );
		}
	    }
	    close($response);
	    if ( defined($journalURL) ) {
		if ( $journalURL ne $bibCodes{$bibCode}->{'entry'}->{'journalURL'} ) {
		    $bibCodes{$bibCode}->{'entry'}->{'journalURL'} = $journalURL;
		    print "   update journal URL for bibcode ".$bibCodes{$bibCode}->{'entry'}->{'bibCode'}." to: ".$journalURL."\n";
		}
	    }
	} else {
	    die("Failed to resolve DOI for bibcode ".$bibCodes{$bibCode}->{'entry'}->{'bibCode'}.": ".$retcode." ".$curl->strerror($retcode)." ".$curl->errbuf."\n");
	}
    }
    # Update repo tags.
    if ( exists($bibCodes{$bibCode}->{'entry'}->{'commit'}) ) {
	my $message = "\"Publication: ".$bibCodes{$bibCode}->{'entry'}->{'title'}." by ".$bibCodes{$bibCode}->{'entry'}->{'author'}." (".$bibCodes{$bibCode}->{'entry'}->{'year'}.")\"";
	if ( exists($bibCodes{$bibCode}->{'entry'}->{'arXiv'}) ) {
	    my $tag = "publication/arXiv/".$bibCodes{$bibCode}->{'entry'}->{'arXiv'};
	    if ( exists($tags{$tag}) ) {
		++$tags{$tag};
	    } else {
		push(@newTags,"git tag -a ".$tag." ".$bibCodes{$bibCode}->{'entry'}->{'commit'}." -m ".$message);
	    }
	}
	if ( exists($bibCodes{$bibCode}->{'entry'}->{'bibCode'}) ) {
	    (my $bibcodeGitified = $bibCodes{$bibCode}->{'entry'}->{'bibCode'}) =~ s/\./_/g;
	    my $tag = "publication/bibcode/".$bibcodeGitified;
	    if ( exists($tags{$tag}) ) {
		++$tags{$tag};
	    } else {
		push(@newTags,"git tag -a ".$tag." ".$bibCodes{$bibCode}->{'entry'}->{'commit'}." -m ".$message);
	    }
	}
	if ( exists($bibCodes{$bibCode}->{'entry'}->{'doi'}) ) {
	    my $tag = "publication/doi/".$bibCodes{$bibCode}->{'entry'}->{'doi'};
	    if ( exists($tags{$tag}) ) {
		++$tags{$tag};
	    } else {
		push(@newTags,"git tag -a ".$tag." ".$bibCodes{$bibCode}->{'entry'}->{'commit'}." -m ".$message);
	    }
	}
    }
}
# Add deletes for any obsoleted tags.
foreach my $tag ( keys(%tags) ) {
    push(@newTags,"git tag -d ".$tag)
	if ( $tags{$tag} == 0 && $tag =~ m/^publication\// );
}
print "...done\n";

# Write updated database file.
open(my $database,">","publications.xml");
print $database $xml->XMLout($publications,RootName => "publications");
close($database);

# Send a Slack notification for any new tags needed.
if ( scalar(@newTags) > 0 ) {
    print "New tags to be created:\n\t".join("\n\t",@newTags)."\n";
    my $data =
    {
	tags => join("\n",@newTags)."\n"
    };
    my $json = encode_json($data);
    system("curl -X POST -H 'Content-type: application/json' --data '".$json."' ".$slackURL);
} else {
    print "No new tags to be created\n";
}

exit;

