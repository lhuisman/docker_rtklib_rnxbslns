#!/usr/bin/perl -w
package toolbox_neu;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(neu2xyz plh2xyz xyz2neu xyz2plh deg2rad rad2deg stdxyz2neu);

# Constants defined by the World Geodetic System 1984 (WGS84)
my $a = 6378137;
my $b = 6356752.3142;
my $e2 = 6.69437999014 * 0.001;
my $e12 = 6.73949674228 * 0.001;
my $f = 1 / 298.257223563;
my $pi = 4 * atan2(1, 1); 

sub neu2xyz{
    my $n = $_[0];
    my $e = $_[1];
    my $u = $_[2];
    my $phi = $_[3];
    my $lam = $_[4];
    my $h = $_[5];

    my($X, $Y, $Z) = plh2xyz ($phi, $lam, $h);
    $phi = deg2rad($phi);
    $lam = deg2rad($lam);
    my $dx = -sin($phi) * cos($lam) * $n - sin($lam) * $e + cos($phi) * cos($lam) * $u;
    my $dy = -sin($phi) * sin($lam) * $n + cos($lam) * $e + cos($phi) * sin($lam) * $u;
    my $dz = cos($phi) * $n + 0 * $e + sin($phi) * $u;
    my $x = $X + $dx;
    my $y = $Y + $dy;
    my $z = $Z + $dz;

    return ($x, $y, $z);
}

sub plh2xyz{
    my $phi = deg2rad($_[0]);
    my $lam = deg2rad($_[1]);
    my $h = $_[2];

    my $N = $a / sqrt(1 - $e2 * (sin($phi) ** 2));
    my $x = ($N + $h) * cos($phi) * cos($lam);
    my $y = ($N + $h) * cos($phi) * sin($lam);
    my $z = ($N - $e2 * $N + $h) * sin($phi);

    return ($x, $y, $z);
}

sub xyz2neu{
    my $x = $_[0];
    my $y = $_[1];
    my $z = $_[2];
    my $phi = deg2rad($_[3]);
    my $lam = deg2rad($_[4]);
    my $h = $_[5];

    my $n = -sin($phi) * cos($lam) * $x - sin($phi) * sin($lam) * $y + cos($phi) * $z;
    my $e = -sin($lam) * $x + cos($lam) * $y;
    my $u =  cos($phi) * cos($lam) * $x + cos($phi) * sin($lam) * $y + sin($phi) * $z;

    return ($n, $e, $u);
} 

sub xyz2plh{
    my $x = $_[0];
    my $y = $_[1];
    my $z = $_[2];
    
    my $b = (1-$f) * $a;
    my $r  = sqrt(($x ** 2) + ($y ** 2));
    my $u    = atan2 ( $z * $a , $r * $b ); 
    my $phi  = atan2 ( $z + ($e2 / (1-$e2) * $b) * (sin($u) ** 3) , $r - ($e2 * $a) * (cos($u) ** 3) );
    my $N = $a / sqrt(1 - $e2 * (sin($phi) ** 2)); 
    my $lam = atan2($y, $x);
    my $h = $r / cos($phi) - $N; 

    return (rad2deg($phi), rad2deg($lam), $h);
}

sub deg2rad{
    my $rad = $_[0] * $pi / 180;
}

sub rad2deg{
    my $rad = $_[0] * 180 / $pi;
}

sub stdxyz2neu{
    my $x = $_[0];
    my $y = $_[1];
    my $z = $_[2];
    my $phi = deg2rad($_[3]);
    my $lam = deg2rad($_[4]);
    my $h = $_[5];

    my $n = (-sin($phi) * cos($lam) * $x * -sin($phi) * cos($lam) * $x) + (- sin($phi) * sin($lam) * $y * - sin($phi) * sin($lam) * $y) + (cos($phi) * $z *cos($phi) * $z);
    my $e = (-sin($lam) * $x * -sin($lam) * $x) + (cos($lam) * $y *cos($lam) * $y);
    my $u = (cos($phi) * cos($lam) * $x * cos($phi) * cos($lam) * $x) + ( cos($phi) * sin($lam) * $y * cos($phi) * sin($lam) * $y) + (sin($phi) * $z * sin($phi) * $z);

    return (sqrt($n), sqrt($e), sqrt($u));
} 
