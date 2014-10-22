/*#############################################################################
# This software is being provided to you, the LICENSEE, by the Linguistic     #
# Data Consortium (LDC) and the University of Pennsylvania (UPENN) under the  #
# following license.  By obtaining, using and/or copying this software, you   #
# agree that you have read, understood, and will comply with these terms and  #
# conditions:                                                                 #
#                                                                             #
# Permission to use, copy, modify and distribute, including the right to      #
# grant others the right to distribute at any tier, this software and its     #
# documentation for any purpose and without fee or royalty is hereby granted, #
# provided that you agree to comply with the following copyright notice and   #
# statements, including the disclaimer, and that the same appear on ALL       #
# copies of the software and documentation, including modifications that you  #
# make for internal use or for distribution:                                  #
#                                                                             #
# Copyright 1994 by the University of Pennsylvania.  All rights reserved.     #
#                                                                             #
# THIS SOFTWARE IS PROVIDED "AS IS"; LDC AND UPENN MAKE NO REPRESENTATIONS OR #
# WARRANTIES, EXPRESS OR IMPLIED.  By way of example, but not limitation,     #
# LDC AND UPENN MAKE NO REPRESENTATIONS OR WARRANTIES OF MERCHANTABILITY OR   #
# FITNESS FOR ANY PARTICULAR PURPOSE.                                         #
#############################################################################*/

/*************************************************************
 * sentag.c
 *------------------------------------------------------------
 * written by:  David Graff, Linguistic Data Consortium
 * usage:       [-l addrlist]
 *
 * Intended to do the best possible sentence tagging of
 * text data from journalistic sources.  Input format is
 * rigidly defined as:
 *
 *	<art.idstr>
 *	<p.idstr.1>
 *	One entire paragraph is written on one line. That's all.
 *	</p>
 *	<p.idstr.2>
 *	There's effectively no limit on line length.
 *	</p>
 *	</art>
 *
 * There may be any number of paragraphs per article.
 * Output format is:
 *
 *	<art.idstr>
 *	<p.idstr.1>
 *	<s.idstr.1.1>
 *	One entire sentence is written on one line.
 *	</s>
 *	<s.idstr.1.2>
 *	That's all.
 *	</s>
 *	</p>
 *	<p.idstr.2>
 *	<s.idstr.2.1>
 *	There's effectively no limit on line length.
 *	</s>
 *	</p>
 *	</art>
 *
 * This program operates as a filter; by default, it looks in
 * "./addressforms" for a list of sentence-internal abbreviations;
 * the argument "-l abbrevfile" can override the default.
 */

#include <stdio.h>
#include <string.h>
#include <ctype.h>

/* increased to keep from crashing on Gigaword, kdv 
   also increased size of some of the fixed arrays
   later in the code 
#define BUFSIZE 4096
#define MAXABRV 2048
#define MAXBRKS 128
#define IDLEN   64
*/

#define BUFSIZE 128000
#define MAXABRV 128000
#define MAXBRKS 32768
#define IDLEN   32768

char *abbrevs[MAXABRV];
int n_abbrevs = 0;
int n_mid_abbrevs;
int pid, sid;


main( ac, av )
  int ac;
  char **av;
{
    FILE *fp;
    int i, j;
    char idstr[IDLEN], buf[BUFSIZE];

/* Determine where to find list of mid-sentence abbrevs
 */
    if ( ac == 3 && !strcmp( av[1], "-l" )) {
	if (( fp = fopen( av[2], "r" )) == NULL ) {
	    fprintf( stderr, "Unable to open addrlist file %s\n", av[2] );
	    exit(1);
	}
    } else if ( ac > 1 ) {
	fprintf( stderr, "Usage: %s [-l addrlist]\n", av[0] );
	exit(1);
    } else if (( fp = fopen( "addrlist", "r" )) == NULL ) {
	fprintf( stderr, "Unable to open ``addrlist'' file\n" );
	exit(1);
    }

/* Load definite within-sentence abbrevs into global array
 */
    while ( fgets( buf, BUFSIZE, fp ) != NULL )
	if ( buf[0] != '#' )
	    abbrevs[ n_abbrevs++ ] = strdup( strtok( buf, "." ));
    fclose( fp );
    n_mid_abbrevs = n_abbrevs;

/* Add some special abbrevs to the list
 */
    abbrevs[ n_abbrevs++ ] = strdup( "Dr" );
    abbrevs[ n_abbrevs++ ] = strdup( "St" );

/* Scan and tag text data
 */
    while ( gets( buf ))
    {
	if ( buf[0] == '<' )
	    switch ( buf[1] )
	    {
	      case 'a':
		i = 5;
		j = 0;
		while ( j < IDLEN && ( idstr[j] = buf[i] ) != '>' ) {
		    i++; j++;
		}
		idstr[j] = 0;
		pid = 0;
		break;

	      case 'p':
		sid = 0;
		break;

	      case '/':
		if (( buf[2] == 'p' && sid ) ||
		    ( buf[2] == 'a' && pid ))
		    puts( buf );
		break;

	      default:
		fprintf( "Unsuitable input:\n%s\n  --  Aborting.\n", buf );
		exit(1);
	    }
	else
	    sentBreak( buf, idstr );
    }

	/* added to make sure all files were completed without error, kdv */
	fprintf( stderr, "sentag: GOOD FILE\n" );
}


char *ucs = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
char *lcs = "abcdefghijklmnopqrstuvwxyz";
char *crp_abbrv[] = { "CORP", "INC", "CO", "PLC", "LTD", "BHD", "CIE",
		      "DEPT", "LTDA", "MFG", "SPA" };
int n_crp_abbrv = 11;
char *time_zone[] = { "EST", "EDT", "PST", "PDT", "CST", "CDT", "MST", "MDT", "GMT" };
int n_time_zone = 9;
char *s_init_wd[] = { "THE", "BUT", "HE", "IN", "IT", "A", "AND", "THAT",
		      "THEY", "THIS", "FOR", "AT", "AS", "SHE", "TO", "IF",
		      "ON", "I", "HIS", "WHILE", "ONE", "SOME", "WITH", "WHEN",
		      "AN", "AFTER", "BOTH", "LAST", "WE", "ITS", "THERE", "THESE",
		      "SO", "NOW", "BY", "THATS", "EVEN", "ALL", "SINCE", "OTHER",
		      "MANY", "ALTHOUGH", "UNDER", "THOUGH", "THOSE", "ALSO", "OF",
		      "AMONG", "STILL", "EACH", "ACCORDING", "THEN", "MOST", "SUCH",
		      "INSTEAD", "HOWEVER", "MEANWHILE", "THEIR", "INDEED", "WHAT",
		      "ABOUT", "YET", "MORE", "YOU", "TODAY", "MOREOVER", "FIRST",
		      "THUS", "THROUGH", "NOT", "FORMER", "ONCE", "HES", "BEFORE",
		      "LIKE", "UNTIL", "JUST", "HER", "SEVERAL", "MY", "FROM",
		      "UNLIKE", "ONLY", "SEPARATELY", "LATE", "HERE", "EARLIER",
		      "NEXT", "NEITHER", "LATER", "EVERY", "WERE", "SAYS", "OVER",
		      "OTHERS", "BESIDES", "BASED", "BIG", "ADDS", "WHATS",
		      "UNFORTUNATELY", "THEYRE", "SMALL", "SIMILARLY", "RATHER",
		      "NOR", "MUCH", "HOW", "CURRENTLY", "WHY", "OUR", "OR", "IM",
		      "ASKED", "ANY", "ALMOST", "SHES", "SHORTLY", "CAN", "YOURE",
		      "USING", "NONETHELESS", "NEARLY", "MAYBE", "MAY", "DO",
		      "OUTSIDE", "NONE", "NOBODY", "ALONG", "YES", "WEVE", "SHOULD",
		      "RECENTLY", "PART", "NEVER", "LET", "LESS", "HIGHER",
		      "EXCLUDING", "BEYOND", "YOUR", "WOULD", "UPON", "SOON",
		      "RUMORS", "OBVIOUSLY", "IS", "HERES", "FAR", "EVER", "AGAIN",
		      "ADDED", "WERE", "WAS", "UNLESS", "PUT", "MADE", "KNOWN", "IVE",
		      "HAVE", "HAVING", "FEW", "CURRENT", "AMID", "ADDING", "YEARS",
		      "WRITTEN", "WORST", "WHETHER", "TOO", "THROUGHOUT", "THEREFORE",
		      "SURELY", "REMOVING", "PURELY", "OFTEN", "LIKEWISE", "INITIAL",
		      "FURTHERMORE", "EXPECT", "DETAILS", "COULD", "ARE", "\0" };

/* made bigger, kdv
#define MAXWDLEN 64
*/
#define MAXWDLEN 4096

#define DoNextPeriod continue

sentBreak( buf, idstr )
  char *buf, *idstr;
{
	/* made bigger, kdv
    char *period[256], *start, perchr, nxtwd[MAXWDLEN];
	*/
    char *period[4096], *start, perchr, nxtwd[MAXWDLEN];

    char *nxtch, *nxtuc, *nxtsp, *prvch, *prvsp, *endwd, *prvwd, *endpg;
    int n_per, i, j, k;

    n_per = 0;
    nxtuc = start = buf;
    endpg = buf + strlen( buf ) -1;

 /* Locate all possible sentence terminations in this paragraph;
  * if none, assume it is not really a paragraph & just return.
  */
    while (( nxtsp = strpbrk( nxtuc, ".?!" )) != NULL ) {
	period[n_per++] = nxtuc = nxtsp;
	nxtuc++;
    }
    if ( ! n_per )
	return;

 /* Check each possible sentence break, using a variety of
  * heuristics...  At each stage, if evidence indicates a
  * clear decision, write the tagged sentence if appropriate,
  * and continue on to the next candidate.
  */
    for ( i=0; i<n_per; i++ )
    {
	nxtch = period[i];
	prvch = period[i] -1;

 /* For this to be a valid break, there must be a space
  * and an upper-case letter following
  */
	if (( nxtuc = strpbrk( period[i], ucs )) == NULL ||
	    ( nxtsp = strchr( period[i], ' ' )) == NULL )
	    DoNextPeriod;

 /* If a digit or other punctuation follows before the next
  * space, this cannot be a sentence break (this handles
  * medial periods in strings of initials, like "U.S.", "p.m."
  */
	while ( ++nxtch < nxtsp )
	    if ( strchr( ".,;:-?!'0123456789", *nxtch ))
		break;
	if ( nxtch < nxtsp && ( *nxtch != '\'' || *(nxtch+1) == 's' ))
	    DoNextPeriod;
	else
	{
 /* Before going on, check whether nxtuc precedes nxtsp; if so,
  * this is probably a typo (space after period was elided);
  * we should fix it and continue to treat this as a candidate
  */
	    if ( nxtuc < nxtsp ) {
		for ( endwd = ++endpg; endwd > period[i]; endwd-- )
		    *(endwd+1) = *endwd;
		for ( j=i+1; j<n_per; j++ )
		    period[j]++;
		nxtsp = nxtuc++;
            }
        }

 /* Make sure nxtsp points as far to the right as possible
  * before checking distance to nxtuc; allowable distance is
  * up to 3 chars, to allow for intervening quote and paren.
  * (but don't allow an intervening space)
  */
	while ( *( nxtsp +1 ) == ' ' )
	    nxtsp++;
	if ( nxtuc > nxtsp + 3 ||
	   ( nxtuc == nxtsp + 3 && *( nxtuc -1 ) == ' ' ))
	    DoNextPeriod;

 /* If next token after period is a corporate abbrev, this is
  * not a break
  */
	j = k = 0;
	while ( k < MAXWDLEN && nxtuc[j] != ' ' ) {
	    if ( isalpha( nxtuc[j] ))
		nxtwd[k++] = toupper( nxtuc[j] );
	    j++;
	}
	if ( k < MAXWDLEN ) {
	    nxtwd[k] = 0;
	    for ( j=0; j<n_crp_abbrv; j++ )
		if ( !strcmp( nxtwd, crp_abbrv[j] ))
		    break;
	    if ( j < n_crp_abbrv )
		DoNextPeriod;
	} else {
	    fprintf( stderr, "TYPO? <p.%s.%d> %s\n", idstr, pid, start );
	    DoNextPeriod;
	}

 /* Inspect the token that precedes the period
  */
	perchr = *period[i];
	*period[i] = 0;

	if (( prvsp = strrchr( start, ' ' )) != NULL )
	{

 /* This block looks at a pre-break token that is not sentence-initial.
  * Make sure we point to the first alphanumeric character, if any
  */
	    endwd = prvsp +1;
	    while ( *endwd && !isalnum( *endwd ))
		*endwd++;
	    if ( ! *endwd ) { /* This was probably an ellipsis "..." */
		*period[i] = perchr;
		tagSentence( start, nxtsp, idstr );
		start = nxtsp + 1;
		DoNextPeriod;
	    }
    
 /* - if token ends in a bracket or quote, this is a clear sentence break
  */
	    if ( strchr( "\")}]", *prvch ))
	    {
		*period[i] = perchr;
		tagSentence( start, nxtsp, idstr );
		start = nxtsp + 1;
		DoNextPeriod;
	    }

 /* - if token does not begin with upper-case, and is not a time designation
  *	("a.m" or "p.m") followed by a time-zone name, and is not "vs" or "excl",
  *	then this is a real break
  */
	    if ( !isupper( *endwd )) {
		if ( strstr( endwd, ".m" )) {
		    for ( j=0; j<n_time_zone; j++ )
			if ( !strcmp( nxtwd, time_zone[j] ))
			    break;
		    if ( j < n_time_zone ) {
			*period[i] = perchr;
			DoNextPeriod;
		    }
		}
		if ( strcmp( endwd, "vs" ) && strcmp( endwd, "excl" )) {
		    *period[i] = perchr;
		    tagSentence( start, nxtsp, idstr );
		    start = nxtsp + 1;
		}
		*period[i] = perchr;
		DoNextPeriod;
	    }

 /* - if it is one of the definite within-sentence abbrevs,
  *	this clearly is not a sentence break
  */
	    for ( j=0; j<n_mid_abbrevs; j++ )
		if ( !strcasecmp( endwd, abbrevs[j] ))
		    break;
	    if ( j < n_mid_abbrevs ) {
		*period[i] = perchr;
		DoNextPeriod;
	    }

 /* - if it is "Dr" or "St", preceded by a capitalized word,
  *	with only a space intervening, this could be a valid break,
  *	but unlikely -- just issue a warning and don't call it a break
  */
	    for ( ; j<n_abbrevs; j++ )
		if ( !strcasecmp( endwd, abbrevs[j] ))
		    break;
	    if ( j < n_abbrevs ) {
		*prvsp = 0;
		prvwd = strrchr( start, ' ' );
		if ( prvwd == NULL ) {
		    *prvsp = ' ';
		    *period[i] = perchr;
		    DoNextPeriod;
		}
		while ( *prvwd && !isalpha( *prvwd ))
		    prvwd++;
		
		if ( ! *prvwd || !isupper( *prvwd ) ||
		      strpbrk( prvwd, ",.:;\"')]}" ) ||
		      strchr( "{[(\"`", *(prvsp+1) )) {
		    *prvsp = ' ';
		    *period[i] = perchr;
		    DoNextPeriod;
		}
		*prvsp = ' ';
		*period[i] = perchr;
		/* don't print out the warning, kdv
		   fprintf( stderr, "ADR? <p.%s.%d> %s\n", idstr, pid, start ); */
		DoNextPeriod;
	    }

 /* - if it is a single letter, this is almost certainly
  *	not a real break (it's a first or middle initial)
  */
	    if ( strlen( endwd ) == 1 ) {
		*period[i] = perchr;
		DoNextPeriod;
	    }

 /* At this point, we are looking at a non-initial multi-char token that
  * begins with upper-case, is not a clear mid-sentence abbrev, and is
  * followed by a capitalized word that is not a corporate abbrev.
  * If the "period" character is actually "?" or "!", OR (the token
  * contains lower case and, if a corp-abbrev, is not followed by "(")
  * then this is almost certainly a real break (if it is a corp-abbrev
  * followed by "(", this is most likely not a break)
  */
	    if ( perchr != '.' ) {
		*period[i] = perchr;
		tagSentence( start, nxtsp, idstr );
		start = nxtsp + 1;
		DoNextPeriod;
	    }
	    if ( strpbrk( endwd, lcs )) {
		for ( j=0; j<n_crp_abbrv; j++ )
		    if ( !strcasecmp( endwd, crp_abbrv[j] ))
			break;
		*period[i] = perchr;
		if ( j == n_crp_abbrv || *(nxtsp+1) != '(' ) {
		    tagSentence( start, nxtsp, idstr );
		    start = nxtsp + 1;
		}
		DoNextPeriod;
	    }

 /* Now we reach the truly ambiguous case: a sequence of upper-case
  * (possibly initials) followed by a capitalized token (e.g. "U.S.
  * Treasury" or "A.G. Edwards"; if it is an acronym (e.g. "NASA"),
  * this is most likely a real break.
  */
	    if ( strspn( endwd, ucs ) == strlen( endwd )) {
		*period[i] = perchr;
		tagSentence( start, nxtsp, idstr );
		start = nxtsp + 1;
		DoNextPeriod;
	    }

 /* Finally, we must determine whether the next token is likely to
  * be a sentence-initial word, rather than a continuation of a
  * proper name (i.e. "U.S. The" vs. "U.S. Navy" -- failing this
  * criterion does not mean we don't have a break, but the error
  * rate of calling it a non-break is diminished.  As a result, the
  * predominant error should be run-on sentences (missed breaks).
  */
	    j = 0;
	    while ( *s_init_wd[j] && strcmp( nxtwd, s_init_wd[j] ))
		j++;

	    *period[i] = perchr;
	    if ( *s_init_wd[j] )
	    {
		tagSentence( start, nxtsp, idstr );
		start = nxtsp + 1;
	    }
	    DoNextPeriod;

	} /* prvsp != NULL */

	else

	{ /* prvsp == NULL */
 /* This block looks at a sentence-initial token preceding
  * the period; if "period" is acually "?!", this is a real break;
  * otherwise, if the token looks like any kind of abbreviation,
  * this is not a real break
  */
	    if ( perchr != '.' ) {
		*period[i] = perchr;
		tagSentence( start, nxtsp, idstr );
		start = nxtsp + 1;
		DoNextPeriod;
	    }
	    endwd = start;
	    while ( *endwd && !isalpha( *endwd ))
		endwd++;
	    if ( ! *endwd ) {
		*period[i] = perchr;
		DoNextPeriod;
	    }
	    for ( j=0; j<n_abbrevs; j++ )
		if ( !strcasecmp( endwd, abbrevs[j] ))
		    break;
	    if ( j < n_abbrevs || strlen( endwd ) == 1 || strchr( endwd, '.' )) {
		*period[i] = perchr;
		DoNextPeriod;
	    }
	    *period[i] = perchr;
	    tagSentence( start, nxtsp, idstr );
	    start = nxtsp + 1;
	    DoNextPeriod;
	}
    } /* for (i=0; i<n_per; i++ ) */

/* If there is still character data in the buffer, call it a sentence
 */
    if ( start + 2 < endpg )
	tagSentence( start, endpg, idstr );
}


tagSentence( start, end, idstr )
  char *start, *end, *idstr;
{
	/* made bigger, kdv 
    char sent[1024], *si, *so;
	*/

    char sent[32768], *si, *so;

    int alpha;

    si = start;
    so = sent;
    alpha = 0;

    while ( si < end ) {
	alpha |= isalpha( *si );
	*so++ = *si++;
    }
    *so = 0;

    if ( ! alpha )
	return;

    if ( ! sid ) {
	if ( ! pid )
	    printf( "<art.%s>\n", idstr );
	printf( "<p.%s.%d>\n", idstr, ++pid );
    }
    printf( "<s.%s.%d.%d>\n%s\n</s>\n", idstr, pid, ++sid, sent );
}
