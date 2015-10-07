#! /usr/bin/perl

use strict;
use Twig;
use Data::Dumper;
use Getopt::Long;
use Switch;

my $file1;
my $file2;
my $output;
my $tag_elem;
my $dup=0;
my $missing=0;
my $type;
my $result = GetOptions ('file1=s' => \$file1,
								'file2=s' => \$file2,
								'output=s' => \$output,
								'tag_elements=s' => \$tag_elem,
								 'type=s' => \$type);

if (!defined($output))
{
				$output = "diff_out";
}
#print "$file1 and $file2\n";SK
#print "this is file2 $file2 \n";SK
open(my $fh,"<",$file2) or die ("file not found"); 
open(my $fh_out,">",$output) or die ("cannot create output file");

###############################################################parsing file1#########################################################################################
my $count_xml = 0;
my %hash_xml;
my %hash_csv;
my %hash_xml2;
my $count_dup = 0;

my $xpath = "BugInstance";  
my $twig = new XML::Twig(TwigHandlers => {
								$xpath => \&parse_routine
								});
print "this is file1 --- $file1";
$twig->parsefile($file1);

my $twig2 = new XML::Twig(TwigHandlers => {
								$xpath => \&parse_routine2
								});
$twig2->parsefile($file2);


#parse file1
sub parse_routine {
				my $start_line;
				my $end_line;
				my ($tree,$elem) = @_;
				my $file_name = $elem->first_child('BugLocations')->first_child('Location')->first_child('SourceFile')->field;
				$file_name = lc($file_name);
				if($type ==2){
					$file_name =~ s/(.*?)\///;
				}

				if ( $elem->first_child('BugLocations')->first_child('Location')->first_child('StartLine') != 0)
				{
								$start_line = $elem->first_child('BugLocations')->first_child('Location')->first_child('StartLine')->field;
				}
				else
				{
								$start_line = 'NA';
				}

				if ($elem->first_child('BugLocations')->first_child('Location')->first_child('EndLine') != 0)
				{
								$end_line = $elem->first_child('BugLocations')->first_child('Location')->first_child('EndLine')->field;
				}
				else
				{
								$end_line = 'NA';
				}
				my $bug_code;
				if ($elem->first_child('BugCode') != 0)
				{
								$bug_code = $elem->first_child('BugCode')->field;
								$bug_code = lc($bug_code);
				}
				my $location = $elem->first_child('BugLocations')->first_child('Location')->{'att'}->{primary};
				my $bug_id  = $elem->{'att'}->{id};
				my $bug_msg;
				if ($elem->first_child('BugMessage') != 0)
				{
								$bug_msg = $elem->first_child('BugMessage')->field;
								$bug_msg =~ s/"//g; 
												$bug_msg = lc ($bug_msg);
								$bug_msg =~ s/\s+$//;
				}
				my $tag;
				switch ($tag_elem)
				{
								case "4" {$tag = $file_name.':'.$start_line.":".$end_line.":".$bug_code.":".$bug_msg}
								case "3" {$tag = $file_name.':'.$start_line.":".$end_line.":".$bug_code}
								case "2" {$tag = $file_name.':'.$start_line.":".$end_line}
								case "1" {$tag = $file_name}
				}
				if (!exists($hash_xml{$tag}))
				{
								$hash_xml{$tag} = {'count'=>1,'bugid'=>$bug_id, 'startline'=>$start_line, 'endline'=>$end_line, 'filename'=>$file_name,'bugcode'=>$bug_code};
								$count_xml++;
				}
				else
				{
								$hash_xml{$tag}->{count} = $hash_xml{$tag}->{count}+1;
								$hash_xml{$tag}->{bugid} = $hash_xml{$tag}->{bugid}."\n\t".$bug_id;
								$count_dup++;	
				}
				$tree->purge;

}

#parse file2
sub parse_routine2 {	
				print "calling parse_routine2\n";
				my $start_line_csv;
				my $end_line_csv;
				my $count_csv =0;		
				my ($tree_csv,$elem_csv) = @_;
				if ($elem_csv->first_child('BugLocations') == 0){
								next;
				}
				my $file_name_csv = $elem_csv->first_child('BugLocations')->first_child('Location')->first_child('SourceFile')->field;
				$file_name_csv = lc($file_name_csv);
				if($type==1){
					$file_name_csv =~ s/(.*?)\///;
				}
				if ( $elem_csv->first_child('BugLocations')->first_child('Location')->first_child('StartLine') != 0)
				{
								$start_line_csv = $elem_csv->first_child('BugLocations')->first_child('Location')->first_child('StartLine')->field;
				}
				else
				{
								$start_line_csv = 'NA';
				}
				if ($elem_csv->first_child('BugLocations')->first_child('Location')->first_child('EndLine') != 0)
				{
								$end_line_csv = $elem_csv->first_child('BugLocations')->first_child('Location')->first_child('EndLine')->field;
				}
				else
				{
								$end_line_csv = 'NA';
				}
				my $bug_code_csv;
				if ($elem_csv->first_child('BugCode') != 0)
				{
								$bug_code_csv = $elem_csv->first_child('BugCode')->field;
								$bug_code_csv = lc($bug_code_csv);
				}
				my $location_csv = $elem_csv->first_child('BugLocations')->first_child('Location')->{'att'}->{primary};
				my $bug_id_csv  = $elem_csv->{'att'}->{id};
				my $bug_msg_csv;
				if ($bug_msg_csv = $elem_csv->first_child('BugMessage') != 0)
				{
								$bug_msg_csv = $elem_csv->first_child('BugMessage')->field;
								$bug_msg_csv =~ s/"//g; 
												$bug_msg_csv = lc ($bug_msg_csv);
								$bug_msg_csv =~ s/\s+$//;
				}
				my $tag_csv;
				switch ($tag_elem)
				{
								case "4" {$tag_csv = $file_name_csv.':'.$start_line_csv.':'.$end_line_csv.':'.$bug_code_csv.":".$bug_msg_csv}
								case "3" {$tag_csv = $file_name_csv.':'.$start_line_csv.':'.$end_line_csv.':'.$bug_code_csv}
								case "2" {$tag_csv = $file_name_csv.':'.$start_line_csv.':'.$end_line_csv}
								case "1" {$tag_csv = $file_name_csv}
				}

				print "in parse routine 2 tag value is $tag_csv\n";
				if ($hash_csv{$tag_csv} == 0)
				{
								#hash_csv{$tag_csv} = {'count'=>1,'bugid'=>$bug_id_csv, 'startline'=>$start_line_csv, 'endline'=>$end_line_csv, 'location'=>$location_csv};
								$hash_csv{$tag_csv} = {'count'=>1,'bugid'=>$bug_id_csv, 'startline'=>$start_line_csv, 'endline'=>$end_line_csv, 'filename'=>$file_name_csv,'bugcode'=>$bug_code_csv};
								$count_csv++;
				}
				else
				{
								$hash_csv{$tag_csv}->{count} = $hash_csv{$tag_csv}->{count}+1;
								$hash_csv{$tag_csv}->{bugid} = $hash_csv{$tag_csv}->{bugid}.",".$bug_id_csv;
				}
				$tree_csv->purge;
}	



#my $tb = Text::Table->new("Bug Id", "Start Line" , "End Line");
print $fh_out "\n\tBugID\tStartLine\t\tEndLine\t\tBugCode\t\t\tFileName\n";
my $elem_xml;
my $elem_csv2;
my $count_cmp = 0;
print "-----hash_csv value ---\n";
print Dumper(\%hash_csv);
print "------hash xml value ---- \n";
print Dumper(\%hash_xml);
foreach my $elem_xml (keys %hash_xml)
{
				$count_cmp++;
				$elem_csv2 = $elem_xml;
				print "----- elem_csv -----";
				print Dumper(\$elem_csv2); 

				print "----  hash_csv{$elem_csv2}------\n";
				print Dumper(\$hash_csv{$elem_csv2});

				if (( $hash_csv{$elem_csv2}==0))
				{
								print "not an exact match $elem_csv2";
								$missing++;
								print $fh_out "-\t $hash_xml{$elem_xml}->{bugid}\t\t$hash_xml{$elem_xml}->{startline}\t\t$hash_xml{$elem_xml}->{endline}\t$hash_xml{$elem_xml}->{bugcode}\t\t$hash_xml{$elem_xml}->{filename}\n";
#tb->load([$hash_xml{$elem_xml}->{bugid},$hash_xml{$elem_xml}->{startline},$hash_xml{$elem_xml}->{endline}]);
				}
				else
				{
								$dup++;
								print "is an exact match $elem_csv2";
#tb->load([$hash_csv{$elem_xml}->{bugid},$hash_csv{$elem_xml}->{startline},$hash_csv{$elem_xml}->{endline}]);
								print $fh_out "+\t$hash_xml{$elem_xml}->{bugid}\t\t$hash_xml{$elem_xml}->{startline}\t\t$hash_xml{$elem_xml}->{endline}\t$hash_xml{$elem_xml}->{bugcode}\t\t$hash_xml{$elem_xml}->{filename}\n";
				}
}
#print $tb;
my $hash_csv_count = keys %hash_csv;
my $hash_xml_count = keys %hash_xml;
printf $fh_out "\n-------Summary--------\n";
print $fh_out "\nTotal differences found in $file1 = $hash_xml_count\n";
print $fh_out "\nTotal differences found in $file2 = $hash_csv_count\n";
print $fh_out "\nNumber of Bug Instances present in both $file1 and $file2= $dup\n ";
print $fh_out "\nNumber of Bug Instances present in $file1 but NOT in  $file2= $missing\n \n";
close ($fh) or die ("unable to close the xml file");
close ($fh_out) or die ("unable to close the csv file");


