#!/usr/bin/perl
#
# Copyright (C) 2014 Daniel "Trizen" Șuteu <echo dHJpemVueEBnbWFpbC5jb20K | base64 -d>.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# License: GPLv3
# Date: 15 May 2014
# Edit: 17 May 2014
# Website: http://github.com/trizen/fbrowse-tray
# Generic name: A simple tray file browser.

# ---------------------------------------------------------
# Recursively browse filesystem through a GTK+ tray applet.
# ---------------------------------------------------------

use 5.016;
use strict;
use warnings;

use Gtk3 qw(-init);
use File::MimeInfo qw();    # File::MimeInfo::Magic is better, but slower...
use Encode qw(decode_utf8);

my $pkgname = 'fbrowse-tray';
my $version = 0.03;

my %opt = (
           m => 'menu',
           i => 'file-manager',
           f => $ENV{FILEMANAGER} // 'pcmanfm',
          );

sub usage {
    my ($code) = @_;
    print <<"USAGE";
usage: $0 [options] [dir]

options:
    -r            : order files before directories
    -t            : set the path of the file as tooltip
    -e            : get the mimetype by extension only (faster)
    -i [name]     : change the status icon (default: $opt{i})
    -f [command]  : command to open the files with (default: $opt{f})
    -m [size]     : size of the menu icons (default: $opt{m})
                    more: dnd, dialog, button, small-toolbar, large-toolbar

example:
    $0 -f thunar -m dnd /my/dir
USAGE
    exit($code // 0);
}

sub version {
    print "$pkgname $version\n";
    exit 0;
}

# Parse arguments
if (@ARGV && chr ord $ARGV[0] eq '-') {
    require Getopt::Std;
    Getopt::Std::getopts('ti:m:f:rhve', \%opt)
      || die "Error in command-line arguments!";
    $opt{h} && usage(0);
    $opt{v} && version();
}

@ARGV == 1 || usage(2);

# Cache the current icon theme
$opt{icon_theme} = Gtk3::IconTheme::get_default();

#
## Main menu
#
{
    my $dir  = decode_utf8(shift @ARGV);
    my $icon = 'Gtk3::StatusIcon'->new;
    $icon->set_from_icon_name($opt{i});
    $icon->set_visible(1);
    $icon->signal_connect('button-release-event' => sub { create_main_menu($icon, $dir, $_[1]) });
    'Gtk3'->main;
}

# -------------------------------------------------------------------------------------

sub add_browse_here {
    my ($menu, $dir) = @_;

    # Append 'Browser here...'
    my $browse_here = 'Gtk3::ImageMenuItem'->new("Browse here...");
    $browse_here->signal_connect('activate' => sub { system "$opt{f} \Q$dir\E &" });
    $menu->append($browse_here);

    return 1;
}

# Add content of a directory as a submenu for an item
sub create_submenu {
    my ($item, $dir) = @_;

    # Create a new menu
    my $menu = 'Gtk3::Menu'->new;

    # Add 'Browse here...'
    add_browse_here($menu, $dir);

    # Append an horizontal separator
    $menu->append('Gtk3::SeparatorMenuItem'->new);

    # Add the dir content in this new menu
    add_content($menu, $dir);

    # Set submenu for item to this new menu
    $item->set_submenu($menu);

    # Make menu content visible
    $menu->show_all;

    return 1;
}

# -------------------------------------------------------------------------------------

# Append a directory to a submenu
sub append_dir {
    my ($submenu, $dirname, $dir) = @_;

    # Create the dir submenu
    my $dirmenu = 'Gtk3::Menu'->new;

    # Create a new menu item
    my $item = 'Gtk3::ImageMenuItem'->new($dirname);

    # Set icon
    $item->set_image('Gtk3::Image'->new_from_icon_name('inode-directory', $opt{m}));

    # Set a signal (activates on click)
    $item->signal_connect('activate' => sub { create_submenu($item, $dir); $dirmenu->destroy });

    # Set the submenu to the entry item
    $item->set_submenu($dirmenu);

    # Append the item to the submenu
    $submenu->append($item);

    return 1;
}

# -------------------------------------------------------------------------------------

# Returns true if a given icon exists in the current icon-theme
sub is_icon_valid {
    state %mem;
    $mem{$_[0]} //= $opt{icon_theme}->has_icon($_[0]);
}

# Returns a valid icon name based on file's mime-type
sub file_icon {
    my ($filename, $file) = @_;

    state %alias;
    my $mime_type = (
                     (
                      $opt{e}
                      ? File::MimeInfo::globs($filename)
                      : File::MimeInfo::mimetype($file)
                     ) // return 'unknown'
                    ) =~ tr{/}{-}r;

    exists($alias{$mime_type})
      && return $alias{$mime_type};

    {
        my $type = $mime_type;
        while (1) {
            if (is_icon_valid($type)) {
                return $alias{$mime_type} = $type;
            }
            elsif (is_icon_valid("gnome-mime-$type")) {
                return $alias{$mime_type} = "gnome-mime-$type";
            }
            $type =~ s{.*\K[[:punct:]]\w++$}{} || last;
        }
    }

    {
        my $type = $mime_type;
        while (1) {
            $type =~ s{^application-x-\K.*?-}{} || last;
            if (is_icon_valid($type)) {
                return $alias{$mime_type} = $type;
            }
        }
    }

    $alias{$mime_type} = 'unknown';
}

# -------------------------------------------------------------------------------------

# Append a file to a submenu
sub append_file {
    my ($submenu, $filename, $file) = @_;

    # Create a new menu item
    my $item = 'Gtk3::ImageMenuItem'->new($filename);

    # Set icon
    $item->set_image('Gtk3::Image'->new_from_icon_name(file_icon($file), $opt{m}));

    # Set tooltip
    $opt{t} && $item->set_property('tooltip_text', $file);

    # Set a signal (activates on click)
    $item->signal_connect('activate' => sub { system "$opt{f} \Q$file\E &" });

    # Append the item to the submenu
    $submenu->append($item);

    return 1;
}

# -------------------------------------------------------------------------------------

# Read a content directory and add it to a submenu
sub add_content {
    my ($submenu, $dir) = @_;

    my (@dirs, @files);
    opendir(my $dir_h, $dir) or return;
    while (defined(my $filename = readdir($dir_h))) {

        # Ignore hidden files
        next if chr ord $filename eq '.';

        # UTF-8 decode the filename
        $filename = decode_utf8($filename);

        # Join directory with filename
        my $abs_path = "$dir/$filename";

        # Readlink
        if (-l $abs_path) {
            $abs_path = readlink($abs_path) // next;
            if (not chr ord $abs_path eq '/') {
                require File::Spec;
                $abs_path = File::Spec->catfile($dir, $abs_path);
            }
            -e $abs_path or next;
        }

        # Collect the files and dirs
        push +((-d _) ? \@dirs : \@files), [$filename =~ s/_/__/gr, $abs_path];
    }
    closedir $dir_h;

    my @calls = ([\&append_dir => \@dirs], [\&append_file => \@files]);
    foreach my $call ($opt{r} ? reverse(@calls) : @calls) {
        $call->[0]->($submenu, $_->[0], $_->[1]) for sort { fc($a->[0]) cmp fc($b->[0]) } @{$call->[1]};
    }

    return 1;
}

# -------------------------------------------------------------------------------------

# Create the main menu and populate it with the content of $dir
sub create_main_menu {
    my ($icon, $dir, $event) = @_;

    my $menu = 'Gtk3::Menu'->new;

    if ($event->button == 1) {
        add_content($menu, $dir);
    }
    elsif ($event->button == 3) {

        # Create a new menu item
        my $exit = 'Gtk3::ImageMenuItem'->new('Quit');

        # Set icon
        $exit->set_image('Gtk3::Image'->new_from_icon_name('exit', $opt{m}));

        # Set a signal (activates on click)
        $exit->signal_connect('activate' => sub { 'Gtk3'->main_quit(); exit });

        # Append the item to the menu
        $menu->append($exit);
    }

    $menu->show_all;
    $menu->popup(undef, undef, sub { Gtk3::StatusIcon::position_menu($menu, $icon) }, [1, 1], 0, 0);

    return 1;
}

# -------------------------------------------------------------------------------------
