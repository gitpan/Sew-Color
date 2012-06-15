package Sew::Color;

use 5.010001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Sew::Color ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
#package Sew::Color; 
#
our $VERSION='1.00'; 
#
#use base 'Exporter';
our @EXPORT=(
             'rgb',   # rgb('Brother','405') returns the red green and blue colors of this thread. 
			 'name',  # returns english name of color, eg 'Bright Red'. Caution, not unique. 
			 'code',  # code('Brother',$r,$g,$b) gives the closest thread code to the given rgb 
			          # in array context, returns (code, error distance) using a simple 3d color
					  # space model. 
					  # 1st parameter may be a manufacturers name, empty (for all)
					  # a comma seperate list, or an array reference containing single manufacturers
			 'manlist',
			 'custom'
		    ) ; 
my $colorlist=''; 

sub get_color_list 
{ 
# Brother,Black,100,28,26,28
$colorlist={}; 
while (<DATA>)
{
   m/^ *#/ and next; 
   chomp;  
   my @x=split(/,/); 
   my @rgb; 
   @rgb=@x[3..5]; 
   exists($colorlist->{$x[0]}) or  $colorlist->{$x[0]}={}; 
   $colorlist->{$x[0]}->{$x[2]}={}; 
   $colorlist->{$x[0]}->{$x[2]}->{name}=$x[1]; 
   $colorlist->{$x[0]}->{$x[2]}->{rgb}=\@rgb; 
} 
close DATA; 
} 
sub rgb
{
  my ($man,$code)=@_; 

  $colorlist or get_color_list(); 

  my $r=$colorlist->{$man}->{$code}->{rgb}; 
  return @$r; 
}
sub name
{
  my ($man,$code)=@_; 

  $colorlist or get_color_list(); 

  my $r=$colorlist->{$man}->{$code}->{name}; 
  return $r; 
}

sub manlist
{
  $colorlist or get_color_list(); 
  return keys %$colorlist; 
} 

# give a list of threads that you have for custom searches. 
# can be Brother 405 406 407 Maderia 1005 102 
sub custom
{
  $colorlist or get_color_list(); 
  my @mankeys=keys %$colorlist; 
  my $man=''; 
  my $nmk; 
  if (@_==0)
  { 
	for $man  (@mankeys)
	{
	  for my $code (keys %{$colorlist->{$man}})
	  {
		  delete $colorlist->{$man}->{$code}->{custom}; 
	  } 
	} 
    return; 
  } 
  for my $t (@_) 
  {
	 my $nmk;
	 $nmk=''; 
	 ($nmk)=grep { $t eq $_ } @mankeys; 
	 defined $nmk or $nmk=''; 
	 #if (0<grep { $t eq $_ } @mankeys)
	 if ($nmk ne '') 
	 {
	    $man=$nmk; 
		next; 
	 }
	 # else its a code. 
	 die "Error no manufacturer given in call to custom for code $t or mispelt manufacturer!" if ($man eq ''); 
	 die "Invalid code '$t' for manufacturer $man in call to custom" if (!exists($colorlist->{$man}->{$t}));
	 $colorlist->{$man}->{$t}->{'custom'}=1; 
  } 
} 
  	
sub code
{
  my ($man,$r,$g,$b)=@_; 
  my $custom=0; 
  my @mans; 

  $colorlist or get_color_list(); 

  my @mankeys=keys %$colorlist; 
  my $err=10000; 
  my $c='' ; # return value; 
  my $mk=''; 

  if (ref($man))
  {
	@mans=@$man; 
  }
  else
  {
    @mans=($man); 
  } 
  @mans=map { split(/,/,$_) }  @mans;   
  @mans=grep {$_ ne '' } @mans; 
  if (grep { $_ eq 'custom' } @mans ) 
  {
     $custom=1; 
	 @mans=grep { $_ ne 'custom'  } @mans; 
  } 

  for my $mankey (@mankeys)
  {
    next if (@mans>0 and 0==grep {$mankey eq $_ } @mans); # only use the wanted keys; 
    for my $code (keys %{$colorlist->{$mankey}})
	{
			#print "#3 $mankey $code\n"; 
	   next if ($custom and !exists $colorlist->{$mankey}->{$code}->{'custom'} ) ; 
	   my $rgb=$colorlist->{$mankey}->{$code}->{rgb}; 
	   my @rgb=@$rgb; 
	   my $d3=($r-$rgb[0])**2+($g-$rgb[1])**2+($b-$rgb[2])**2; 
	   $d3=sqrt($d3); 
	   #print "$code ($r,$g,$b) - (@rgb) $d3\n"; 
	   if ($d3<$err)
	   {
		  $c=$code; 
		  $err=$d3; 
		  $mk=$mankey; 
	   } 
	} 
  }
  $err='' if ($c eq ''); 
  if (wantarray) { return ($c,$mk,$err); } 
  return $c; 
}
return 1; 
=head1 NAME 

 Sew:Color - rgb colours for various manufactures of coloured embroidery thread.   

=head1 ABSTRACT

  Module for determining rgb colours of various manufacturers of embroidering thread 
  and the codes that go with them. 

=head1 SYNOPSIS 

 use Sew::Color
 my @rgb=rgb('Brother', '502'); 
 my $name=name('Brother','502'); 

 print "$name (@rgb)\n"; 

=head1 DESCRIPTION

 These calls return respectively the red green and blue components of the colour of the thread 
 and the 'English' name of the thread colour. The colour components will be in the range 0 to 255. 
 In this case, Brother thread number 502. 
 Be aware that the name of the thread colour is not unique, there are some codes that have 
 the same name, although they are mostly different. 

 The above code prints out 
    
    Mint Green (148 190 140) 

 code(Manufacturer,red,green.blue)

 This function does a simple search in the colour space to find the colour that is closest to the rgb values you provide. 

 The parameters are

   Manufacturer: Can be a single manufacturer, a comma seperated list or an array reference of manufacturers. 
   				 It can be empty to search all known about. 
   red, green, blue are the colour co-ordinates to search for. Distnce is done through a very simple sequential search
                 using a simple 3-d colour model without any weightings. (so rgb all treated the same.) 

 The return values are: 

	In a scalar context, just the code, for example '502'. 
	In an array context it returns a 3 element array, with the following entries

		Manufacturer, eg 'Brother' 
		Thread code, eg '502'
		Error distance, eg 42. This is the distance in linear units scaled to 255 
		between the thread found and the desired colour. Note that it can be more than 255
		(Consider that the diagonal of a cube with side 255 is more than 255. ) but will normally 
		not be. 

=head2 Custom Searches

 If you only have certain threads that you want to search (you dont happen to have the full Madeira
 in your store cupboard!) you can say which ones you do have by using the custom function. This is called as follows

   custom('Manufacturer',list of codes, 'Manufacturer', list of codes ) 

 A call to the code function with the special string 'custom' as manufacturer will search only these threads. 

   custom() 

 will reset all the custom threads. 

=head2 Methods

		rgb(Manufacturer, code) returns a 255-max scaled rgb tripplet. 
		name(Manufacturer,code) returns the "English" name of the colour. 
		code(Manufacturer-list,r,g,b)  returns either the code or an array 
								with the following: (Manufacturer,code,error distance) 

=head1 AUTHOR 

 Mark Winder June 2012. 
 markwin (at) cpan.org 							

=cut   

__DATA__
Brother,Amber Red,333,132,82,76
Brother,Beige,012,220,206,180
Brother,Beige,843,220,210,180
Brother,Black,100,28,26,28
Brother,Black,900,36,38,36
Brother,Blue,405,100,110,172
Brother,Blue,586,132,134,164
Brother,Blue Metallic,995,92,114,148
Brother,Brass,328,148,146,100
Brother,Caribbean,900,156,182,164
Brother,Carmine,158,188,82,108
Brother,Carmine,807,204,62,84
Brother,Clay Brown,224,172,130,116
Brother,Clay Brown,339,164,98,76
Brother,Copper,986,140,86,52
Brother,Cornflower Blue,015,140,146,196
Brother,Cornflower Blue,070,156,154,204
Brother,Cream Brown,010,236,242,188
Brother,Cream Brown,331,236,230,172
Brother,Cream Yellow,370,236,222,140
Brother,Cream Yellow,812,236,214,140
Brother,Dark Brown,058,92,70,60
Brother,Dark Brown,717,100,82,68
Brother,Dark Fuchsia,107,212,70,108
Brother,Dark Fuchsia,126,164,74,100
Brother,Dark Grey,707,76,70,84
Brother,Dark Grey,747,92,82,92
Brother,Dark Olive,473,148,154,124
Brother,Dark Olive,517,124,118,92
Brother,Dark Pink,991,140,62,84
Brother,Deep Gold,214,204,154,84
Brother,Deep Gold,354,196,158,116
Brother,Deep Green,808,68,82,60
Brother,Deep Rose,024,180,110,140
Brother,Deep Rose,086,236,130,164
Brother,Denim,950,132,138,172
Brother,Electric Blue,420,76,126,180
Brother,Emerald Green,485,100,114,92
Brother,Emerald Green,507,68,130,84
Brother,Flesh Pink,124,228,210,204
Brother,Flesh Pink,152,220,162,188
Brother,Fresh Green,027,188,210,156
Brother,Fresh Green,442,188,202,148
Brother,Fresh Green,989,204,198,140
Brother,Glory,964,140,106,140
Brother,Government Gold Metallic,999,188,162,108
Brother,Green Metallic,994,84,126,100
Brother,Grey,817,132,122,124
Brother,Harvest Gold,206,236,206,76
Brother,Harvest Gold,334,236,218,140
Brother,Hot Pink,155,212,114,148
Brother,Khaki,242,212,166,140
Brother,Khaki,348,212,186,132
Brother,Lavender,604,196,162,204
Brother,Lavender,804,132,114,172
Brother,Lavender,988,44,74,140
Brother,Leaf Green,463,100,154,124
Brother,Leaf Green,509,92,162,100
Brother,Lemon Yellow,202,236,234,156
Brother,Light Blue,017,172,214,228
Brother,Light Blue,987,156,194,220
Brother,Light Brown,255,132,102,92
Brother,Light Brown,323,164,130,108
Brother,Light Lilac,133,212,134,164
Brother,Light Lilac,810,204,162,196
Brother,Light Pink,990,140,90,108
Brother,Lilac,612,164,118,172
Brother,Lilac,624,220,154,188
Brother,Lime Green,444,164,174,116
Brother,Lime Green,513,140,198,100
Brother,Linen,025,228,210,188
Brother,Linen,307,236,230,212
Brother,Magenta,620,164,106,148
Brother,Majestic,903,148,126,132
Brother,Meadow,953,148,174,108
Brother,Mint Green,502,148,190,140
Brother,Moss Green,515,124,134,68
Brother,Olive Green,519,92,90,68
Brother,Opal Metallic,899,252,246,244
Brother,Orange,208,228,170,76
Brother,Peacock Blue,415,84,102,100
Brother,Peppermint,992,60,122,108
Brother,Pewter,704,148,146,164
Brother,Pewter,745,140,134,132
Brother,Pewter,996,124,122,148
Brother,Pink,085,236,170,188
Brother,Pink Ice,945,228,198,204
Brother,Polar White,001,236,238,236
Brother,Prussian Blue,007,76,78,148
Brother,Pumpkin,126,236,130,84
Brother,Pumpkin,322,236,162,124
Brother,Purple,614,148,98,164
Brother,Purple,635,172,94,156
Brother,Red,149,212,70,84
Brother,Red,800,220,70,68
Brother,Red Brown,264,196,122,116
Brother,Red Brown,337,212,138,100
Brother,Red Metallic,993,172,70,68
Brother,Rich Gold,998,188,134,44
Brother,Royal Purple,869,180,78,124
Brother,Russet Brown,330,140,122,76
Brother,Salmon Pink,079,220,186,188
Brother,Salmon Pink,122,212,166,180
Brother,Seabreeze,902,132,150,148
Brother,Seacrest,505,132,182,180
Brother,Seacrest,542,156,178,164
Brother,Silver,005,180,182,188
Brother,Silver Metallic,997,212,206,196
Brother,Sky Blue,019,108,142,172
Brother,Sky Blue,512,172,210,212
Brother,Tangerine,209,244,126,76
Brother,Tangerine,336,228,130,84
Brother,Teal Green,483,148,166,148
Brother,Teal Green,534,76,126,116
Brother,Tropic Sunrise,901,212,134,108
Brother,Ultramarine,406,84,94,156
Brother,Ultramarine,575,100,114,172
Brother,Vermillion,030,244,114,108
Brother,Violet,613,156,106,156
Brother,Warm Grey,399,204,190,180
Brother,Warm Grey,706,156,134,124
Brother,White,000,236,234,220
Brother,White,001,244,246,244
Brother,Wisteria Violet,003,172,178,212
Brother,Wisteria Violet,607,156,146,188
Brother,Yellow,205,236,230,116
Madeira,,1000,44,42,44
Madeira,,1001,228,238,252
Madeira,,1002,236,238,252
Madeira,,1003,236,238,236
Madeira,,1004,204,206,212
Madeira,,1005,204,210,220
Madeira,,1006,44,42,44
Madeira,,1007,44,42,44
Madeira,,1008,44,42,44
Madeira,,1009,44,42,44
Madeira,,1010,196,198,196
Madeira,,1011,180,186,188
Madeira,,1012,164,178,188
Madeira,,1013,244,214,204
Madeira,,1014,244,186,196
Madeira,,1015,236,186,180
Madeira,,1016,228,154,156
Madeira,,1017,244,194,172
Madeira,,1018,244,186,172
Madeira,,1019,236,170,164
Madeira,,1020,252,142,132
Madeira,,1021,188,86,52
Madeira,,1022,244,234,188
Madeira,,1023,244,222,108
Madeira,,1024,252,166,36
Madeira,,1025,212,134,36
Madeira,,1026,252,198,148
Madeira,,1027,156,186,204
Madeira,,1028,92,142,172
Madeira,,1029,44,142,188
Madeira,,1030,148,174,196
Madeira,,1031,204,162,188
Madeira,,1032,124,106,156
Madeira,,1033,116,78,140
Madeira,,1034,156,66,100
Madeira,,1035,100,50,68
Madeira,,1036,92,50,52
Madeira,,1037,196,18,36
Madeira,,1038,148,46,52
Madeira,,1039,172,42,52
Madeira,,1040,148,138,140
Madeira,,1041,108,118,132
Madeira,,1042,36,86,124
Madeira,,1043,44,54,68
Madeira,,1044,44,50,60
Madeira,,1045,132,206,188
Madeira,,1046,92,178,156
Madeira,,1047,164,198,172
Madeira,,1048,132,158,92
Madeira,,1049,116,166,76
Madeira,,1050,60,146,68
Madeira,,1051,4,134,68
Madeira,,1052,60,118,116
Madeira,,1053,236,186,172
Madeira,,1054,180,130,124
Madeira,,1055,212,178,140
Madeira,,1056,156,106,76
Madeira,,1057,156,110,84
Madeira,,1058,116,70,60
Madeira,,1059,68,58,52
Madeira,,1060,188,178,164
Madeira,,1061,252,222,172
Madeira,,1062,148,142,132
Madeira,,1063,132,126,116
Madeira,,1064,252,202,20
Madeira,,1065,236,122,36
Madeira,,1066,252,218,156
Madeira,,1067,244,226,172
Madeira,,1068,252,190,4
Madeira,,1069,252,182,20
Madeira,,1070,212,170,108
Madeira,,1071,236,234,220
Madeira,,1072,196,194,180
Madeira,,1073,212,222,212
Madeira,,1074,156,186,212
Madeira,,1075,140,174,204
Madeira,,1076,4,82,148
Madeira,,1077,236,82,68
Madeira,,1078,244,86,44
Madeira,,1079,4,138,84
Madeira,,1080,164,126,172
Madeira,,1081,180,46,76
Madeira,,1082,212,194,172
Madeira,,1083,252,206,84
Madeira,,1084,212,190,164
Madeira,,1085,188,186,180
Madeira,,1086,204,206,204
Madeira,,1087,196,198,196
Madeira,,1088,108,178,180
Madeira,,1089,108,170,180
Madeira,,1090,4,134,140
Madeira,,1091,4,118,132
Madeira,,1092,156,198,212
Madeira,,1093,44,194,204
Madeira,,1094,4,182,204
Madeira,,1095,4,170,196
Madeira,,1096,4,130,164
Madeira,,1097,188,214,196
Madeira,,1098,76,126,116
Madeira,,1099,196,202,164
Madeira,,1100,188,210,180
Madeira,,1101,68,142,76
Madeira,,1102,156,158,100
Madeira,,1103,52,78,60
Madeira,,1104,204,202,156
Madeira,,1105,180,170,132
Madeira,,1106,156,142,84
Madeira,,1107,236,102,124
Madeira,,1108,236,146,172
Madeira,,1109,212,82,140
Madeira,,1110,196,46,108
Madeira,,1111,204,182,204
Madeira,,1112,84,74,132
Madeira,,1113,244,206,196
Madeira,,1114,244,194,196
Madeira,,1115,244,194,196
Madeira,,1116,236,178,196
Madeira,,1117,212,98,140
Madeira,,1118,148,154,156
Madeira,,1119,164,82,108
Madeira,,1120,236,190,204
Madeira,,1121,228,182,204
Madeira,,1122,84,58,108
Madeira,,1123,244,230,188
Madeira,,1124,252,202,84
Madeira,,1125,244,178,52
Madeira,,1126,188,134,100
Madeira,,1127,220,194,172
Madeira,,1128,172,154,140
Madeira,,1129,76,58,52
Madeira,,1130,68,54,52
Madeira,,1131,60,54,52
Madeira,,1132,140,190,212
Madeira,,1133,44,130,188
Madeira,,1134,4,94,156
Madeira,,1135,252,218,116
Madeira,,1136,148,130,116
Madeira,,1137,252,142,12
Madeira,,1138,204,190,172
Madeira,,1140,132,134,52
Madeira,,1141,156,114,124
Madeira,,1142,180,154,140
Madeira,,1143,76,114,156
Madeira,,1144,140,114,92
Madeira,,1145,100,66,60
Madeira,,1146,212,38,44
Madeira,,1147,180,18,52
Madeira,,1148,228,146,164
Madeira,,1149,220,198,180
Madeira,,1150,220,226,140
Madeira,,1151,172,182,196
Madeira,,1152,252,142,116
Madeira,,1153,180,198,212
Madeira,,1154,220,70,100
Madeira,,1155,252,154,92
Madeira,,1156,124,118,68
Madeira,,1157,124,110,76
Madeira,,1158,124,70,60
Madeira,,1159,212,162,60
Madeira,,1160,84,118,140
Madeira,,1161,52,82,92
Madeira,,1162,28,70,76
Madeira,,1163,100,122,140
Madeira,,1164,76,66,84
Madeira,,1166,36,66,132
Madeira,,1167,36,74,124
Madeira,,1169,140,154,76
Madeira,,1170,92,110,44
Madeira,,1171,244,178,76
Madeira,,1172,236,154,44
Madeira,,1173,196,118,60
Madeira,,1174,132,58,52
Madeira,,1175,60,106,148
Madeira,,1176,28,138,188
Madeira,,1177,4,114,172
Madeira,,1178,252,106,68
Madeira,,1179,212,90,84
Madeira,,1180,236,202,84
Madeira,,1181,140,38,52
Madeira,,1182,124,46,68
Madeira,,1183,140,50,84
Madeira,,1184,196,34,76
Madeira,,1185,4,102,100
Madeira,,1186,172,2,68
Madeira,,1187,180,26,84
Madeira,,1188,124,62,116
Madeira,,1189,28,42,20
Madeira,,1190,156,126,60
Madeira,,1191,148,114,60
Madeira,,1192,164,114,36
Madeira,,1193,164,162,76
Madeira,,1194,84,70,20
Madeira,,1195,140,182,180
Madeira,,1196,124,110,20
Madeira,,1198,164,178,196
Madeira,,1199,36,22,36
Madeira,,1212,140,146,164
Madeira,,1217,228,182,164
Madeira,,1218,156,94,92
Madeira,,1219,140,162,172
Madeira,,1220,228,130,140
Madeira,,1221,172,66,52
Madeira,,1222,204,198,172
Madeira,,1223,252,206,44
Madeira,,1224,228,190,84
Madeira,,1225,204,142,68
Madeira,,1226,220,150,108
Madeira,,1227,132,166,164
Madeira,,1228,84,74,76
Madeira,,1229,68,50,52
Madeira,,1230,52,30,28
Madeira,,1232,172,162,196
Madeira,,1233,76,66,100
Madeira,,1234,188,54,100
Madeira,,1235,156,106,148
Madeira,,1236,76,42,52
Madeira,,1238,132,38,52
Madeira,,1239,84,78,76
Madeira,,1240,116,106,108
Madeira,,1241,60,66,68
Madeira,,1242,36,62,92
Madeira,,1243,52,58,76
Madeira,,1244,52,50,60
Madeira,,1245,52,162,132
Madeira,,1246,4,150,140
Madeira,,1247,4,154,116
Madeira,,1248,164,210,108
Madeira,,1249,36,162,68
Madeira,,1250,4,110,76
Madeira,,1251,4,146,76
Madeira,,1252,60,98,108
Madeira,,1253,204,126,84
Madeira,,1254,236,146,132
Madeira,,1255,156,126,76
Madeira,,1256,140,86,44
Madeira,,1257,116,42,12
Madeira,,1258,92,30,20
Madeira,,1259,116,90,84
Madeira,,1260,204,186,140
Madeira,,1261,148,150,204
Madeira,,1263,116,110,164
Madeira,,1264,132,122,156
Madeira,,1266,36,54,156
Madeira,,1267,204,198,156
Madeira,,1270,228,190,132
Madeira,,1272,188,126,76
Madeira,,1273,140,114,68
Madeira,,1274,116,162,204
Madeira,,1275,116,134,188
Madeira,,1276,60,98,156
Madeira,,1277,28,30,76
Madeira,,1278,252,102,20
Madeira,,1279,12,134,124
Madeira,,1280,4,122,100
Madeira,,1281,156,34,60
Madeira,,1282,116,194,172
Madeira,,1284,20,86,92
Madeira,,1286,188,182,188
Madeira,,1287,84,78,84
Madeira,,1288,100,94,100
Madeira,,1289,68,154,164
Madeira,,1290,28,82,84
Madeira,,1291,4,106,124
Madeira,,1292,148,198,196
Madeira,,1293,4,110,116
Madeira,,1294,4,138,164
Madeira,,1295,4,146,172
Madeira,,1296,4,98,132
Madeira,,1297,4,118,164
Madeira,,1298,4,142,124
Madeira,,1299,12,194,180
Madeira,,1301,68,178,132
Madeira,,1302,132,210,156
Madeira,,1303,52,62,52
Madeira,,1304,4,78,68
Madeira,,1305,196,182,156
Madeira,,1306,124,122,100
Madeira,,1307,228,74,84
Madeira,,1308,76,78,68
Madeira,,1309,220,106,164
Madeira,,1310,156,62,124
Madeira,,1311,140,138,188
Madeira,,1312,100,82,116
Madeira,,1313,68,58,92
Madeira,,1315,236,158,172
Madeira,,1317,236,166,164
Madeira,,1318,76,70,76
Madeira,,1319,164,102,140
Madeira,,1320,92,70,100
Madeira,,1321,228,150,188
Madeira,,1322,68,66,124
Madeira,,1323,172,162,52
Madeira,,1328,132,98,92
Madeira,,1329,124,98,84
Madeira,,1330,84,102,164
Madeira,,1334,100,54,108
Madeira,,1335,68,102,164
Madeira,,1336,116,94,84
Madeira,,1337,124,138,124
Madeira,,1338,172,146,116
Madeira,,1339,140,138,132
Madeira,,1340,148,134,52
Madeira,,1341,164,102,100
Madeira,,1342,164,130,116
Madeira,,1343,52,58,100
Madeira,,1344,140,114,84
Madeira,,1347,76,54,20
Madeira,,1348,84,58,28
Madeira,,1349,204,190,124
Madeira,,1350,180,162,68
Madeira,,1351,20,54,60
Madeira,,1352,148,118,20
Madeira,,1353,68,90,132
Madeira,,1354,204,78,116
Madeira,,1356,188,166,188
Madeira,,1357,76,74,52
Madeira,,1358,116,78,76
Madeira,,1359,212,162,52
Madeira,,1360,124,150,164
Madeira,,1361,76,70,76
Madeira,,1362,84,78,100
Madeira,,1363,116,126,148
Madeira,,1364,76,94,116
Madeira,,1365,60,74,100
Madeira,,1366,44,54,108
Madeira,,1367,28,18,36
Madeira,,1368,28,22,52
Madeira,,1369,60,126,68
Madeira,,1370,36,90,68
Madeira,,1371,28,90,84
Madeira,,1372,204,146,52
Madeira,,1373,92,150,196
Madeira,,1374,100,46,52
Madeira,,1375,60,130,164
Madeira,,1376,36,82,108
Madeira,,1377,92,138,84
Madeira,,1378,220,58,44
Madeira,,1379,236,98,76
Madeira,,1380,4,154,132
Madeira,,1381,140,34,60
Madeira,,1382,100,58,68
Madeira,,1383,156,34,84
Madeira,,1384,108,46,60
Madeira,,1385,100,42,52
Madeira,,1386,76,50,68
Madeira,,1387,116,106,132
Madeira,,1388,100,62,92
Madeira,,1389,108,46,68
Madeira,,1390,52,74,68
Madeira,,1391,76,102,92
Madeira,,1392,108,126,116
Madeira,,1393,68,70,52
Madeira,,1394,76,82,68
Madeira,,1395,68,78,68
Madeira,,1396,84,98,84
Madeira,,1397,36,74,60
Madeira,,2010,236,222,188
Madeira,,2011,244,214,132
Madeira,,2012,244,182,196
Madeira,,2013,244,178,196
Madeira,,2014,196,106,196
Madeira,,2015,148,174,220
Madeira,,2016,156,170,212
Madeira,,2017,188,186,188
Madeira,,2018,204,186,172
Madeira,,2019,180,214,180
Madeira,,2020,124,210,148
Madeira,,2021,236,118,164
Madeira,,2022,244,86,52
Madeira,,2023,220,150,36
Madeira,,2024,196,118,44
Madeira,,2025,92,170,204
Madeira,,2026,100,74,132
Madeira,,2027,204,2,4
Madeira,,2028,188,210,148
Madeira,,2029,148,122,20
Madeira,,2030,52,158,196
Madeira,,2031,108,190,68
Madeira,,2032,164,78,20
Madeira,,2033,108,150,52
Madeira,,2034,100,66,76
Madeira,,2035,204,218,188
Madeira,,2036,60,50,164
Madeira,,2037,244,194,212
Madeira,,2038,108,122,196
Madeira,,2039,100,186,124
Madeira,,2040,228,210,84
Madeira,,2050,164,66,148
Madeira,,2051,236,86,164
Madeira,,2052,244,82,156
Madeira,,2053,236,106,36
Madeira,,2054,164,82,52
Madeira,,2055,204,82,116
Madeira,,2056,188,62,76
Madeira,,2057,228,154,212
Madeira,,2058,132,2,4
Madeira,,2059,204,30,36
Madeira,,2060,236,66,60
Madeira,,2101,220,226,212
Madeira,,2102,220,218,196
Madeira,,2103,180,194,180
Madeira,,2105,180,130,140
Madeira,,2106,156,130,124
Madeira,,2140,132,114,140
Madeira,,2141,164,134,132
Madeira,,2142,196,102,84
Madeira,,2143,156,114,68
Madeira,,2144,140,46,36
Madeira,,2145,172,58,12
Madeira,,2146,100,146,76
Madeira,,2147,164,130,84
Madeira,,2148,132,94,60
Madeira,,2149,124,94,52
