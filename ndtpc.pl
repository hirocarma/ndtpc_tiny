#!@perl_bindir@
# Copyright (C) 1999, 2000 and 2001 Sakane Shoichi (sakane@tanu.org).
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of the project nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE PROJECT AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE PROJECT OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# $Id: ndtpc.pl,v 1.19 2002/11/20 03:19:46 sakane Exp $
#
use NKF;

BEGIN {
    use lib '@ndtpc_libdir@';
    $DEFAULT_HOST        = '127.0.0.1';
    $DEFAULT_PORT        = 2882;
    $DEFAULT_RECURSIVE   = 1;
    $DEFAULT_AUTHNAME    = 'ndtp-client';
    $DEFAULT_SEARCH_TYPE = 'a';
}
########

require 'ndtp.pl';

&init_vars;
&parse;

NDTP_open( SO, $hostname, $port ) || die "NDTP open failed";
NDTP_getpriv( SO, $authname )     || die "NDTP get privilege failed";

if ($f_booklist) {
    &print_booklist;
    exit 0;
}
elsif ( !@booklist ) {
    ( @booklist = NDTP_getbooklist(SO) ) || die "NDTP no books found";
}

&select;

# the list of the indexes searched.
%searched = ();
$reclev   = 0;

if ($head) {

    # search by using index
    foreach $book (@booklist) {
        NDTP_setbook( SO, $book ) || printf "NDTP set book failed! ";
        printf "DICT: %s\n", NDTP_getbookname( SO, $book )
          if ( !defined $opt_q );
        &do_search($head);
    }
}
elsif ($word) {

    # search by the word specified.
    foreach $book (@booklist) {
        NDTP_setbook( SO, $book ) || printf "NDTP set book failed! ";
        printf "DICT: %s\n", nkf( "-w", NDTP_getbookname( SO, $book ) )
          if ( !defined $opt_q );
        foreach ( NDTP_gethead( SO, $search_type, $word ) ) {
            &do_search($_);
        }
    }
}

NDTP_close(SO);
exit 0;

########
sub usage {
    my $p = substr( $0, 1 + rindex( $0, '/' ) );
    print
      "$p [-s server] [-p port] [-b books] [-t type] [-l] [-r level] word\n";
    print "$p [-s server] [-p port] [-b books] [-r level] -i header\n";
    print "$p [-s server] [-p port] -B\n";
    print "  -s: specify NDTPD server.            (default: 127.0.0.1)\n";
    print "  -p: specify NDTP port.               (default: 2010)\n";
    print "  -b: specify book numbers.            (default: all)\n";
    print "      like \"-b 1,3\" in case of specifying multiple books\n";
    print "  -t: specify a direction of search.   (default: a)\n";
    print "      either a(forward)or A(backward)or j(keyword) as argument.\n";
    print "  -i: specify search index(header).    (default: none)\n";
    print "      header is such like 54a2:758.\n";
    print "  -S: search synonym too.              (default: no)\n";
    print "  -r: define recursive level.          (default: 1)\n";
    print "  -l: add a newline to be legible.     (default: no)\n";
    print "  -B: print book list.                 (default: no)\n";
    print "  -q: quiet mode.                      (default: no)\n";
    print "  -v: verbose mode.                    (default: no)\n";
    print "  -d: debug mode.\n";
    print "  -h: show this message.\n";

    exit 1;
}

sub do_search {
    my ($head) = @_;

    $searched{$head}++;
    print "<$head>$word\n";
    &print_res( NDTP_getdata( SO, $head ) );
}

sub print_res {
    my @res = @_;
    my @res2;
    my $i;
    my $r;
    my $e;

    $reclev++;

    foreach (@res) {
        $r = $_;    # save

        if ( !$verbose ) {
            s/¢ª(\(Îã\))<([\w]+:[\w]+)>//g;
            s/¡ÚÎà¸ì¡Û ¢Í¢ª<([\w]+:[\w]+)>\w+//g;
        }
        print "\t" x ( $reclev - 1 );
        printf "%s%s\n", $_, $legible;

        if ( $recursive_level >= $reclev ) {
            $_ = $r;
            while (/¢ª\(Îã\)<([\w]+:[\w]+)>/gc) {
                $i = $1;
                if ( !grep( /$i/, keys %searched ) ) {
                    $searched{$i}++;
                    print "\t" x $reclev;
                    print "¢ª(Îã)<$i>\n";
                    print_res( NDTP_getdata( SO, $i ) );
                }
            }

            $_ = $r;
            if ($synonym) {
                $_ = $r;
                while (/¡ÚÎà¸ì¡Û ¢Í¢ª<([\w]+:[\w]+)>(\w+)/gc) {
                    $i = $1;
                    $e = $2;
                    if ( !grep( /$i/, keys %searched ) ) {
                        $searched{$i}++;
                        print "\t" x $reclev;
                        print "¢ª¡ÚÎà¸ì¡Û<$i>$e\n";
                        print_res( NDTP_getdata( SO, $i ) );
                    }
                }
            }

            $_ = $r;
            while (/¢ª<([\w]+:[\w]+)>([\w'`\s¡Ä]+)$/gc) {
                $i = $1;
                $e = $2;
                if ( !grep( /$i/, keys %searched ) ) {
                    $searched{$i}++;

                    print_res( NDTP_getdata( SO, $i ) );
                }
            }
        }
    }

    $reclev--;
}

sub print_booklist {
    printf "Number\tName\n";
    foreach ( NDTP_getbooknames(SO) ) {
        printf "%s\n", nkf( "-w", $_ );
    }
}

########
# parse command line
sub parse {
    use Getopt::Std;
    use Clipboard;
    getopts('t:s:p:b:i:BSr:lvhdq');

    if ($opt_d)           { $DEBUG++; }
    if ($opt_h)           { usage; }
    if ($opt_t)           { $search_type     = $opt_t; }
    if ($opt_s)           { $hostname        = $opt_s; }
    if ($opt_p)           { $port            = $opt_p; }
    if ($opt_b)           { @booklist        = split( /,/, $opt_b ); }
    if ( defined $opt_r ) { $recursive_level = $opt_r; }
    if ($opt_l)           { $legible         = "\n"; }
    if ($opt_v)           { $verbose         = 1; }
    if ($opt_S)           { $synonym         = 1; }
    if ($opt_q)           { $quiet           = 1; }

    if ($opt_B) {
        $f_booklist++;
    }
    elsif ($opt_i) {
        $head = $opt_i;
        die "don't need such a argument, \"$ARGV[0]\" if you use i option.\n"
          if ( $ARGV[0] );
    }
    else {
        if ( $ARGV[0] ) { $word = nkf( "-e", $ARGV[0] ); }
        else {
            $word = nkf( "-e", Clipboard->paste() );
        }
    }
}

sub init_vars {
    $DEBUG           = 0;
    $hostname        = $DEFAULT_HOST;
    $port            = $DEFAULT_PORT;
    $authname        = $DEFAULT_AUTHNAME;
    $search_type     = $DEFAULT_SEARCH_TYPE;
    $synonym         = 0;
    $recursive_level = $DEFAULT_RECURSIVE;
    $verbose         = 0;
    $head            = '';
    $word            = '';
}

sub select {
    use Term::UI;
    use Term::ReadLine;
    if ( !$opt_b ) {
        &print_booklist;
        my $term = Term::ReadLine->new("book");
        my $book_reply =
          $term->get_reply( prompt => "which book use? (default all)", );
        if ($book_reply) { @booklist = split( /,/, $book_reply ); }
    }
    if ( !$opt_t ) {
        my $term         = Term::ReadLine->new("search");
        my $search_reply = $term->get_reply(
            prompt  => "which search type use? (a or A or j.default a)",
            default => 'a',
        );
        $search_type = $search_reply;
    }
}
