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
# $Id: ndtp.pl,v 1.5 2001/11/08 02:12:13 sakane Exp $
#

use Socket;
use NKF;

################
# NDTP libraries.
#

# open connection for NDTP.
# $result = NDTP_open(SO, $hostname, $port);
sub NDTP_open {
    my ( $so,     $hostname, $port ) = @_;
    my ( $name,   $aliases,  $proto );
    my ( $family, $len,      $addr, $server );

    # get the port number if the port is a name.
    if ( $port !~ /^\d+$/ ) {
        ( $name, $aliases, $port ) = getservbyname( $port, 'tcp' );
        if ( !$port ) {

            #print "Can't find ndtp's service number, using 2882";
            $port = 2882;
        }
    }

    # get protocol number
    ( $name, $aliases, $proto ) = getprotobyname('tcp');
    if ( !$proto ) {
        if ( $name eq 'tcp' ) {
            $proto = 6;
        }
        elsif ( $name eq 'udp' ) {
            $proto = 17;
        }
        else {
            $proto = 0;
        }
    }

    # get the sockaddr structure.
    ( $name, $aliases, $family, $len, $addr ) = gethostbyname($hostname);
    $server = pack( 'S n a4 x8', &AF_INET, $port, $addr );

    socket( $so, AF_INET, SOCK_STREAM, $proto ) || return (0);
    connect( $so, $server )                     || return (0);

    return 1;
}

# get privilege.
# $result = NDTP_getpriv(SO, $name);
sub NDTP_getpriv {
    my ( $so, $name ) = @_;
    my $msg;

    $msg = sprintf( "%s%s\n", $NDTP::CMD{'getpriv'}, $name );
    SendMsg( $so, $msg );
    $msg = RecvMsg($so);

    return 1 if $msg =~ /^\$A\n/;
    return 0;
}

# get list of book name.
# a list is "number name\n".
# @list = NDTP_getbooknames(SO);
sub NDTP_getbooknames {
    my ($so) = @_;
    my @list = ();
    my $msg;

    $msg = sprintf( "%s\n", $NDTP::CMD{'getlist'} );
    SendMsg( $so, $msg );
    $msg = '';
    do {
        $msg .= RecvMsg($so);
    } while ( $msg !~ /\$.\n/ );
    @list = split( '\n', $msg );

    # success
    if ( $list[$#list] =~ /^\$\*/ ) {
        pop(@list);
        return @list;
    }

    # failure
    return ();
}

# get the book name by the book number.
# $name = NDTP_getbookname(SO, $book);
sub NDTP_getbookname {
    my ( $so, $book ) = @_;
    my @list = ();
    my $msg;

    %bn = map /^(\d+)\s*(.*)/, NDTP_getbooknames(SO);
    return $bn{$book};
}

# get list of book number.
# @list = NDTP_getbooklist(SO);
sub NDTP_getbooklist {
    my ($so) = @_;

    return map /^(\d+)/, &NDTP_getbooknames($so);
}

# set current book.
# $result = NDTP_setbook(SO, $book);
sub NDTP_setbook {
    my ( $so, $book ) = @_;
    my $msg;

    $msg = sprintf( "%s%s\n", $NDTP::CMD{'setbook'}, $book );
    SendMsg( $so, $msg );
    $msg = RecvMsg($so);

    return 1 if $msg =~ /^\$\*\n/;
    return 0;
}

# search both entry and header.
# @entries = NDTP_getentry(SO, $type, $word);
# $type may be always 'a'.
# If no header found, return 0.
sub NDTP_getentry {
    my ( $so, $type, $word ) = @_;
    my @list = ();
    my $msg;

    $msg = sprintf( "%s%s%s\n", $NDTP::CMD{'gethead'}, $type, $word );
    SendMsg( $so, $msg );
    $msg = '';
    do {
        $msg .= RecvMsg($so);
    } while ( $msg !~ /\$[^0]\n/ );
    @list = split( '\n', $msg );

    return () if $#list == 1;

    pop(@list);
    shift(@list);

    return @list;
}

# search header.
# @heads = NDTP_gethead(SO, $type, $word);
# $type may be always 'a'.
# If no header found, return 0.
sub NDTP_gethead {
    my ( $so, $type, $word ) = @_;
    my %list = ();
    my $msg;

    %list = &NDTP_getentry( $so, $type, $word );

    return values(%list);
}

# get data.
# $data = NDTP_getdata(SO, $head);
sub NDTP_getdata {
    my ( $so, $head ) = @_;
    my $msg;

    $msg = sprintf( "%s%s\n", $NDTP::CMD{'getdata'}, $head );
    SendMsg( $so, $msg );
    $msg = '';
    do {
        $msg .= RecvMsg($so);
    } while ( $msg !~ /\$[^1]\n/ );
    @list = split( '\n', nkf( "-w", $msg ) );

    pop(@list);
    pop(@list);
    shift(@list);

    return @list;
}

# disconnect.
# NDTP_close(SO);
sub NDTP_close {
    my ($so) = @_;
    my $msg;

    $msg = sprintf( "%s\n", $NDTP::CMD{'quit'} );
    SendMsg( $so, $msg );
    close($so);
}

sub NDTP_strerror {
    my ($msg) = @_;

    if ( $msg =~ /^\$\^/ ) {
        print "Server internal error.\n";
    }
    elsif ( $msg =~ /^\$\?/ ) {
        print "Systax error.\n";
    }
    elsif ( $msg =~ /^\$\N/ ) {
        print "No privilege.\n";
    }
    elsif ( $msg =~ /^\$\</ ) {
        print "Invalid book.\n";
    }
    elsif ( $msg =~ /^\$\&/ ) {
        print "Failed to change book.\n";
    }
    else {
        print "Unknown error.\n";
    }
}

sub RecvMsg {
    my ($so) = @_;
    my $msg;
    my $bufsize = 1024;    # XXX

    recv( $so, $msg, $bufsize, 0 );
    printf "R:(%d)%s", length($msg), $msg if $DEBUG;

    return $msg;
}

sub SendMsg {
    my ( $so, $msg ) = @_;

    printf "S:(%d)%s", length($msg), $msg if $DEBUG;
    send( $so, $msg, 0 );
}

package NDTP;

BEGIN {
    %CMD = (
        'getpriv' => 'A',
        'getlist' => 'T',
        'setbook' => 'L',
        'gethead' => 'P',
        'getdata' => 'S',
        'quit'    => 'Q',
    );
}

1;
