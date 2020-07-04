#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 15 May 2014
# http://github.com/trizen

# A simple Gtk2 tray applet file browser - first release.

use utf8;
use 5.016;
use strict;
use warnings;

use Gtk2 qw(-init);
use File::Spec::Functions qw(catfile);

my $dir = $ENV{HOME};    # start dir
my $cmd = 'pcmanfm';     # command to open files with

# Add content of a directory as a submenu for an item
sub create_submenu {
    my ($item, $abs_path) = @_;

    # Create a new menu
    my $menu = 'Gtk2::Menu'->new;

    # Append 'Browser here...'
    my $browse_here = 'Gtk2::ImageMenuItem'->new("Browse here...");
    $browse_here->signal_connect('activate' => sub { system "$cmd \Q$abs_path\E &" });
    $menu->append($browse_here);

    # Append an horizontal separator
    $menu->append('Gtk2::SeparatorMenuItem'->new);

    # Add the dir content in this new menu
    add_content($menu, $abs_path);

    # Set submenu for item to this new menu
    $item->set_submenu($menu);

    # Make menu content visible
    $menu->show_all;
}

# Append a directory to a submenu
sub append_dir {
    my ($submenu, $dirname, $abs_path) = @_;

    # Create the dir submenu
    my $dirmenu = 'Gtk2::Menu'->new;

    # Create a new menu item
    my $item = 'Gtk2::ImageMenuItem'->new($dirname);

    # Set icon
    $item->set_image('Gtk2::Image'->new_from_icon_name('inode-directory', 'menu'));

    # Set a signal (activates on click)
    $item->signal_connect('activate' => sub { create_submenu($item, $abs_path) });

    # Set the submenu to the entry item
    $item->set_submenu($dirmenu);

    # Append the item to the submenu
    $submenu->append($item);
}

# Append a file to a submenu
sub append_file {
    my ($submenu, $filename, $abs_path) = @_;

    # Create a new menu item
    my $item = Gtk2::ImageMenuItem->new($filename);

    # Set icon
    $item->set_image('Gtk2::Image'->new_from_icon_name('gtk-file', 'menu'));

    # Set a signal (activates on click)
    $item->signal_connect('activate' => sub { system "$cmd \Q$abs_path\E &" });

    # Append the item to the submenu
    $submenu->append($item);
}

# Read a content directory and add it to a submenu
sub add_content {
    my ($submenu, $dir) = @_;

    my (@dirs, @files);
    opendir(my $dir_h, $dir) or return;
    while (defined(my $filename = readdir($dir_h))) {

        # Ignore hidden files
        next if chr ord $filename eq '.';

        # Join directory with filename
        -r (my $abs_path = catfile($dir, $filename)) or next;

        # UTF-8 decode the filename shown in menu
        utf8::decode($filename);

        # Collect the files and dirs
        push @{(-d _) ? \@dirs : \@files}, [$filename =~ s/_/__/gr, $abs_path];
    }
    closedir $dir_h;

    my @calls = ([\&append_file => \@files], [\&append_dir => \@dirs]);
    foreach my $call (1 ? reverse(@calls) : @calls) {
        $call->[0]->($submenu, $_->[0], $_->[1]) for sort { fc($a->[0]) cmp fc($b->[0]) } @{$call->[1]};
    }

    return 1;
}

# Create the main menu and populate it with the content of $dir
sub create_main_menu {
    my ($icon, $dir) = @_;

    my $menu = 'Gtk2::Menu'->new;
    add_content($menu, $dir);
    $menu->show_all;
    $menu->popup(undef, undef, sub { Gtk2::StatusIcon::position_menu($menu, 0, 0, $icon) }, [1, 1], 0, 0);

    return 1;
}

#
## Main menu
#

my $icon = 'Gtk2::StatusIcon'->new;
$icon->set_from_icon_name('file-manager');
$icon->set_visible(1);
$icon->signal_connect('button-release-event' => sub { create_main_menu($icon, $dir) });

'Gtk2'->main;
