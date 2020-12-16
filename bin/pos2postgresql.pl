#!/usr/bin/perl -w
use strict;
use warnings;
use File::Basename;
use DBI;
use Time::Piece;
use Getopt::Long;
use Statistics::Basic qw(:all unbias ipres=13);
use lib '.';
use toolbox_neu;



#-- Table: xyzrtklib
#
#-- DROP TABLE xyzrtklib
#
#CREATE TABLE xyzrtklib
#(
#  gid serial NOT NULL,
#  datetime timestamp without time zone,
#  base character varying(25),
#  rover character varying(25),
#  epochs numeric (5),
#  fixedEpochs numeric (5),
#  X_median numeric(14,4),
#  Y_median numeric(14,4),
#  Z_median numeric(14,4),
#  X_mean numeric(14,4),
#  Y_mean numeric(14,4),
#  Z_mean numeric(14,4),
#  X_std numeric(12,5),
#  Y_std numeric(12,5),
#  Z_std numeric(12,5),
#  N_std numeric(12,5),
#  E_std numeric(12,5),
#  U_std numeric(12,5),
#
#  CONSTRAINT sstmtcqltcntrl_pkey PRIMARY KEY (gid)
#)
#WITH (
#  OIDS=FALSE
#);
#ALTER TABLE xyzrtklib
#  OWNER TO postgres;
#----------------------------------------

sub usage{
    my $message = << 'END_MESSAGE';
        
        Incorrect input
        
        Usage:
        pos2postgresql -b <base> -r <rover> -y <year> -d <day of year> -h <hour> -m <min>  -f <path to pos file> -p <postgresql ip>
        
        Example:
        perl /root/bin/pos2postgresql.pl -f /data/pos/2020/261/09/ -b ADR2 -r APEL -y 2020 -d 261 -h 09 -m 10 
        
END_MESSAGE
 
    print $message;
}

sub readPos{

  # Read  rtklib output file return an array 'posdata' with:
  # epoch x y z fix nsat sdn sde sdu sdne sdeu sdun age ratio
  # as well as the number of epochs 'nepochs' and fixed epochs 'nfixepochs'
  #
  # Syntax:
  #      ($nfixepochs, $nepochs, @posdata) =  readPos($posfile);
  #
  # $posfile         station file name
  #
  # Lennard Huisman - GEOpinie 17-09-2020
  # 

  my ($posfile) = @_;
  my (@posdata);
  my (@fields,$debug);
  
  my ($epoch);
  
  my $gps0 = Time::Piece->strptime("06-01-1980 00:00:00", "%d-%m-%Y %H:%M:%S");
  
  open(POSFILE,"$posfile") ||  die ("Error opening $posfile\n");
  
  my $nfixepochs=0;
  my $nepochs=0;
  while (<POSFILE>) {
    chop($_);
    if ($_ =~ /^\s*%/) { next; } # Skips header line starting with %
    @fields=unpack("a5 a11 a15 a15 a15 a4 a4 a9 a9 a9 a9 a9 a9 a7 a7",$_);
    if ($fields[5]==1) {
        my @row;
        $epoch=$gps0 + $fields[0]*7*86400 + $fields[1];
        push(@row, $_) foreach($epoch,$fields[2],$fields[3],$fields[4],$fields[5],$fields[6],$fields[7],$fields[8],$fields[9],$fields[10],$fields[11],$fields[12],$fields[13],$fields[14]);
        push(@posdata,\@row);
        $nfixepochs=$nfixepochs+1;
    }
    $nepochs=$nepochs+1;
  } # End of While
  close (POSFILE);
  
  return ($nfixepochs, $nepochs, @posdata);

}

sub getPosStats {
    my ($nfixepochs, @posdata) = @_;
    
    my (@x, @y, @z);
    for (0..$nfixepochs-1) {
        push(@x,$posdata[$_][1]);
        push(@y,$posdata[$_][2]);
        push(@z,$posdata[$_][3]);
    }
    my $vecX=vector(@x);
    my $vecY=vector(@y);
    my $vecZ=vector(@z);

    my $x_mean=mean($vecX);
    my $y_mean=mean($vecY);
    my $z_mean=mean($vecZ);
    
    my $x_median=median($vecX);
    my $y_median=median($vecY);
    my $z_median=median($vecZ);
    
    my $x_stddev=stddev($vecX);
    my $y_stddev=stddev($vecY);
    my $z_stddev=stddev($vecZ);
    
    my ($phi,$lam,$u)=xyz2plh($x_median,$y_median,$z_median);
    my ($n_stddev, $e_stddev, $u_stddev) = stdxyz2neu($x_stddev, $y_stddev, $z_stddev,$phi,$lam,$u);

    return ($x_median,$y_median,$z_median,$x_mean,$y_mean,$z_mean,$x_stddev,$y_stddev,$z_stddev,$n_stddev,$e_stddev,$u_stddev);
}

sub send2DB{
    my ($data,$database)=@_;

    #----------------------------------------
    # Connection paramters to db
    # TODO: - convert to user input??
    #----------------------------------------
#    my $db_host = '192.168.99.100';
    my $db_host = $database;
#    my $db_host = '10.107.2.2';
    my $db_port = '5432';
    my $db_user = 'postgres';
    my $db_pass = 'postgres';
    my $db_name = "myxyz";

    #----------------------------------------
    #Connect DB
    #----------------------------------------
    my $db = "dbi:Pg:dbname=${db_name};host=${db_host};port=${db_port}";
    my $dbh = DBI->connect($db, $db_user, $db_pass,{ RaiseError => 1, AutoCommit => 1 });
    # add data into postgis
    
        my @fields=split /,/, $data;
        
        $dbh->do("INSERT INTO xyzrtklib (datetime,base,rover,epochs,fixedEpochs,X_median,Y_median,Z_median,X_mean,Y_mean,Z_mean,X_std,Y_std,Z_std,N_std,E_std,U_std)
                values(to_timestamp('$fields[0]','YYYY-DDD HH24:MI'),\'$fields[1]\',\'$fields[2]\',\'$fields[3]\',\'$fields[4]\',\'$fields[5]\',\'$fields[6]\',\'$fields[7]\',\'$fields[8]\',\'$fields[9]\',\'$fields[10]\',\'$fields[11]'\,\'$fields[12]\',\'$fields[13]\',\'$fields[14]\',\'$fields[15]\',\'$fields[16]\');");
        
    $dbh->disconnect();
}

my ($base, $rover, $yyyy, $doy, $hour, $min, $filepath, $database);

GetOptions( 'base=s'  => \$base,
            'rover=s'  => \$rover,
            'yyyy=s'      => \$yyyy,
            'doy=s'       => \$doy,
            'hour=s'      => \$hour,
            'min=s'       => \$min,
            'filepath=s'  => \$filepath,
            'postgres=s'  => \$database
          )
    or usage(); 

my $posfile=$filepath."/".$rover.$base.$yyyy.$doy.$hour.$min.".pos";
my $sessionepoch=$yyyy."-".$doy." ".$hour.":".$min;

my ($nfixepochs, $nepochs,@posdata) = readPos($posfile);

print "\n";
print "Inputfile $posfile for rover $rover and base $base read with $nfixepochs fixed epochs out of $nepochs epochs\n";
print "\n";

my ($x_median,$y_median,$z_median,$x_mean,$y_mean,$z_mean,$x_stddev,$y_stddev,$z_stddev,$n_stddev,$e_stddev,$u_stddev) = getPosStats($nfixepochs, @posdata);
print "\n";
printf ("Statistics: Mean X, Y Z: %.4f  %.4f  %.4f  and StdNEU: %.4f %.4f %.4f \n",$x_mean, $y_mean, $z_mean,$n_stddev, $e_stddev, $u_stddev);
print "\n";

my $dbdata=sprintf("$sessionepoch,$base,$rover,$nepochs,$nfixepochs,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f",$x_median,$y_median,$z_median,$x_mean,$y_mean,$z_mean,$x_stddev,$y_stddev,$z_stddev,$n_stddev,$e_stddev,$u_stddev);
$dbdata =~ s/n\/a/NaN/g;
send2DB($dbdata,$database);

