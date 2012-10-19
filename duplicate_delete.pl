#!/usr/bin/env perl

use strict;
use warnings;

use File::Find;
use File::Spec;
use File::Copy qw/move/;
use File::Basename;

use Digest::MD5; # qw(md5 md5_hex);

my $trash = "trash";

my @hash = ();
my @file_list = ();
my @dir_list = ();
my %digest_list = ();
my @del_list = ();
my $file_count;
my $root_path;


$root_path = $ARGV[0];

find(\&walk, $root_path);

choice_files();

mk_trash();
move_to_trash();

print "End\n";

########################################

sub walk {
    #print $File::Find::name."\n";

    push(@file_list, $File::Find::name);
}


# 重複ファイルの選り分け
sub choice_files {
    foreach my $file (@file_list) {
        my $abs_path = File::Spec->rel2abs($file);
        my $md5hash = make_md5($abs_path);
        next unless defined($md5hash);

        # 重複なし        
        unless ( defined($digest_list{$md5hash}) ) {
            $digest_list{$md5hash} = $abs_path;
        }
        else {
            # 重複あり
            if (length($digest_list{$md5hash}) < length($abs_path)) {
                push(@del_list, $digest_list{$md5hash});
                $digest_list{$md5hash} = $abs_path;
            }
            else { push(@del_list, $abs_path); }

            $file_count += 1;
        }
        #push(@digest_list, make_md5($file));
    }
}

sub make_md5 {
    my $file_name = shift;
    if (-d $file_name) {
        return undef;
    }
    open ( my $fh, '<', $file_name ) or die "Can not open $file_name:$!";
    binmode($fh);

    my $md5 = Digest::MD5->new;#->addfile($fh)->hexdigest;
    $md5->addfile($fh);
     
    return $md5->hexdigest;
}

sub mk_trash {
    if ( -d $trash ) { print "trash directory ... ok.\n"; }
    else {
        mkdir "$trash"
            or die "$trashの作成に失敗しました。:$!";
    }
    
}

sub move_to_trash {
    my $count;

    foreach my $del_file (@del_list) {
        my $result;

        $result = move $del_file, File::Spec->catfile($trash,basename($del_file));
        if ($result) {
            print "$del_file is removed.\n";
            $count += 1;
        }
        else { print "Can not remove $del_file:$!\n"; }

    }
    print "Delete $count files.\n";
}
