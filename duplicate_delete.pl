#!/usr/bin/env perl

use strict;
use warnings;

use File::Find;
use File::Spec;
use File::Copy qw/move/;
use File::Basename;

use Digest::MD5 qw(md5);

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

# 重複ファイルの選り分け
foreach my $file (@file_list) {
    #print $file, "\n";
    my $md5hash = make_md5($file);
    my $abs_path = File::Spec->rel2abs($file);

    if ($digest_list{$md5hash} eq ""){
        # 重複なし
        $digest_list{$md5hash} = $abs_path;
    }
    else {
        # 重複あり
        if (length($digest_list{$md5hash}) < $abs_path) {
            push(@del_list, $digest_list{$md5hash});
            $digest_list{$md5hash} = $abs_path;
        }
        else {
            push(@del_list, $abs_path);
        }
        $file_count += 1;
    }
    #push(@digest_list, make_md5($file));
}

mk_trash();

foreach my $del_file (@del_list) {
    my $result;
    my $count;
    $result = move $del_file, $trash.basename($del_file);
    if ($result) {
        print "$del_file is removed.";
        $count += 1;
    }
    else {
        print "Can not remove $del_file:$!";
    }

    print "Delete $count files.";
}

print "End";

########################################

sub walk {
    #print $File::Find::name;

    push(@file_list, $File::Find::name);
}

sub make_md5 {
    my $file = shift;

    my $digest = md5($file);

    $digest;
}

sub mk_trash {
    mkdir "$trash"
        or die "$trashの作成に失敗しました。:.$!";
    
}
