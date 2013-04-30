#!/usr/bin/perl -w
use strict;


use Text::vCard::Addressbook;

sub photocompare{
	open(DAT1,"> tempphoto1.dat")
		or die "Fehler beim Öffnen von 'tempphoto1.dat': $!\n";
	open(DAT2,"> tempphoto2.dat")
		or die "Fehler beim Öffnen von 'tempphoto1.dat': $!\n";
	print DAT1 $_[0];
	print DAT2 $_[1];

	my $output = qx/compare -metric AE tempphoto1.dat tempphoto2.dat diff.png 2>&1/;
#	print "vor 1.vergleich: $output\n";
	my $diff=0;
	if ($output>0) {$diff=1;}
	$output = qx/compare -fuzz 5% -metric AE tempphoto1.dat tempphoto2.dat diff.png 2>&1/;
#	print "vor 2.vergleich: $output";
	if ($output>0) {$diff+=1;}
	return $diff;
}



my $ab_a = Text::vCard::Addressbook->new(
      { 'source_file' => '/home/peter/Miscellaneous/Programmieren/vcf-compare/00004.vcf', } );
      
my $ab_b = Text::vCard::Addressbook->new(
      { 'source_file' => '/home/peter/Miscellaneous/Programmieren/vcf-compare/00005.vcf', } );

my @a=$ab_a->vcards();
my @b=$ab_b->vcards();      

my %ha;
foreach $a (@a){
	if (defined($a->fullname())){
		$ha{$a->fullname()}=$a;
	}else{
		$ha{$a->as_string()}=$a;
	}
}
my %hb;
foreach $b (@b){
	if (defined($b->fullname())){
#		if ($b->fullname eq "107.7") {
#			print $b->as_string();
#		}
		$hb{$b->fullname()}=$b;
	}else{
		$hb{$b->as_string()}=$b;
	}
}
#print $hb{"Vergiftungszentrale"}->as_string;
#$wert=$hb{"Vergiftungszentrale"};
#if (defined($wert)) {
#	print "Schlüssel gefunden\n";
#}else{
#	print "Schlüssel NICHT gefunden\n";
#}
	
my $vc;
my $vcfn;
my $vcas;

#my @schlussel=keys(%hb);
#foreach (@schlussel){
#	print $_;
#}
#foreach $vc (@a) {
#	print $vc->as_string();
#}

foreach $vc (@a) {
	if (defined($vcfn=$vc->fullname())){ #vc ist mit fullname
#		print "...untersuche $vcfn...\n";
		if (defined($hb{$vcfn})){        #es gibt eine Karte mit gleichem fullname in b
		    #die Karten sind string-identisch:
			if (!((my $t1=$vc->as_string()) eq (my $t2=$hb{$vcfn}->as_string()))){
				#wenn nicht string-identisch: schauen, ob photos drin sind:
				if (defined($vc->photo())||defined($hb{$vcfn}->photo())){
					#photos sind im Spiel, jetzt alle Fälle abkaspern:
					if (!(defined($vc->photo()))){
						print "$vcfn aus Datei a hat kein Photo, aber Datei b schon\n";
					}
					if (!(defined($hb{$vcfn}->photo()))){
						print "$vcfn aus Datei b hat kein Photo, aber Datei a schon\n";
					}
					if (defined($vc->photo())){
						#--> alle Photooperationen für a ausführen:
						#photo entfernen und restlichen inhalt vergleichen, wenn der ok ist dann photovergleich
						my $photonodes1=$vc->get('PHOTO');   #Photoknoten holen
						my $nodeanz1=@$photonodes1;			#Anzahl der Bilder checken (sollte nur 1 sein)
						if ($nodeanz1!=1){
							die ("$t1 hat komischerweise mehr als ein Bild\n");
						}
						my $pattern1=$$photonodes1[0]->as_string();	#Bild als string holen
						$pattern1 = quotemeta($pattern1);			#String als Suchpattern formatieren
						$t1 =~ s/\r\n$pattern1//;						#Bild-String aus Karte entfernen
					}
					if (defined($hb{$vcfn}->photo())){
						#d.h. aber Datei b muss Photo haben, sonst wäre OR-Abfrage oben gescheitert
						# --> alle Photooperationen für b ausführen:
						my $photonodes2=$hb{$vcfn}->get('PHOTO');
						my $nodeanz2=@$photonodes2;
						if ($nodeanz2!=1){
							die ("$t2 hat komischerweise mehr als ein Bild\n");
						}
						my $pattern2=$$photonodes2[0]->as_string();
						$pattern2 = quotemeta($pattern2);
						$t2 =~ s/\r\n$pattern2//;
					}

					# hier sind jetzt beide Karten OHNE Photos
					if (!($t1 eq $t2)) {							#Karten ohne Bilder vergleichen
						print "$vcfn aus Datei a und Datei b sind verschieden\n";
						print "   a: $t1\n";
						print "   b: $t2\n";
					}
					# else {print "$vcfn ohne Photos sind gleich\n";} # Aussage brauch ich nicht
					#nur wenn in a UND b Photos definiert sind photovergleich machen
					if (defined(my $p1=$vc->photo())&&defined(my $p2=$hb{$vcfn}->photo())){
						my $erg=photocompare($p1,$p2);					#Bilder selbst vergleichen
						if ($erg>0){
							print "Photos von $vcfn sind verschieden!\n";
							if ($erg<2){
								print "  ...aber nur ein bisschen :-)\n";
							}
						}
						else {print "   ...und Photos sind gleich\n";}
					}
										
				}
				else {print "Keine Photos involviert; Einträge $vcfn sind verschieden.\n";}
#				my $vcas=$vc->as_string();
#				my $hb_as=$hb{$vcfn}->as_string();
#				print "\t\t$vcas\n";
#				print "\t\t$hb_as\n";
			}
		} #ende es gibt eine Karte mit gleichem fullname
		else { #wenn es keine Karte mit gleichem fullname gibt
			print "Für $vcfn wurde kein Fullname in b gefunden.\n";
		}

	}
	else { #in vc gibt es also keinen fullname
		$vcas=$vc->as_string();
		if (defined($hb{$vcas})){
				#prüfen ob vc und hbinhalt gleich sind
				if (!($vcas eq $hb{$vcas}->as_string())){
					print "$vcas ist verschieden.\n";
				}
		}
		else{
		  print "Für $vcas wurde kein Pendant gefunden.\n";
		}
	}
}	

my @schluessel=keys(%hb);
my $s;
foreach $s (@schluessel){
	if (!defined($ha{$s})){
		print "In zweiter Datei noch zusätzlich gefunden: $s\n";
	}
}

my $z=@a;
print "\nAnzahl einträge: $z \n";

exit;
$vc=$a[264];
my $vc2=$a[263];
my $erg= $vc eq $vc2;
print "Ergebnis: $erg\n";
print $vc->as_string();
my $tels=$vc->get('tel');
my @nodes=@{$tels};
print $nodes[0]->export_data();


#foreach $vc (@a) {
#	print $vc->as_string();
#	my $tels=$vc->get('tel');

#	print $tels->export_data();
#	my $x=$tels->as_string;
#}

