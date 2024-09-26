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
# $Id: ndtp-test.pl,v 1.4 2001/11/08 02:12:13 sakane Exp $
# 

$x = 1;
require 'ndtp.pl';

if ($x == 0) {
	$word = '¤«¤¯';
} elsif ($x == 1) {
	$word = 'sample';
} else {
	$word = 'xxxx';
}

NDTP_open(SO, "127.0.0.1", 2010) || die "NDTP open failed";
NDTP_getpriv(SO, "sakane") || die "NDTP get privilege failed";
#print map $_ .= "\n", NDTP_getbooknames(SO);

foreach $n (NDTP_getbooklist(SO)) {
	print "book = $n\n";
	NDTP_setbook(SO, $n) || die "NDTP set book failed";
	(%heads = NDTP_gethead(SO, 'a', $word)) || print "not found.\n";
	print map NDTP_getdata(SO, $_), %heads;
}

