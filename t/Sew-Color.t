# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Sew-Color.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
BEGIN { use_ok('Sew::Color') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my @c=rgb('Brother','405'); 
# color Blue 405 is 100 110 172

ok(0+@c == 3, 'Array return from rgb function');
ok($c[0] ==100 ,'Red from rgb function' ); 
ok($c[1] ==110 ,'Red from rgb function' ); 
ok($c[2] ==172 ,'Red from rgb function' ); 
ok(name('Brother','405') eq 'Blue','Test of English name'); 
ok(code([''],100,100,170) eq '405' , 'Code Search Test'); 

#ok($c[0] ==100 ,'Red from rgb function' ); 
#ok($c[1] ==110 ,'Red from rgb function' ); 
#ok($c[2] ==172 ,'Red from rgb function' ); 
#ok(name('Brother','405') eq 'Blue','Test of English name'); 
#ok(code([''],100,100,170) eq '405' , 'Code Search Test'); 
