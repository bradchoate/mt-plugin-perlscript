Perl Script
A Plugin for Movable Type

Release 2.0 
August 25, 2007

From Brad Choate
http://www.bradchoate.com/
Copyright (c) 2002-2007, Brad Choate


===========================================================================

INSTALLATION

To install, place the following files into your MT installation:

  (mt home)/plugins/PerlScript/PerlScript.pl
  (mt home)/plugins/PerlScript/lib/MTPerlScript/Plugin.pm


Refer to the Movable Type documentation for more information regarding
plugins.


===========================================================================

DESCRIPTION

This plugin allows you to write Perl code into your templates.


Tags made available through this plugin:

  <MTPerlScript>


===========================================================================

<MTPerlScript>

The following attributes are supported for this tag:

  * preprocess
    If set to '0', it will prevent any MT tags contained within the
    PerlScript block from being evaluated (default is '1').

  * reprocess
    If set to '0', it will prevent any MT tags printed by the PerlScript
    code from being evaluated (default is '1').

You can pass any number of attributes and process them using the '%args'
hash described below.

Here are some convenient variables that you can access within your script:

  * %args: hash containing the arguments passed to the PerlScript tag.
  
  * %stash: Current Movable Type 'stash' containing the context
  variables from parent tags.

  * $dbh: A handle to your Movable Type database (if you're using a database
  for storing your data).

Here's an simple example:

<MTPerlScript multiplier="3">
  $a = 5;
  print $a * $args{multiplier};
</MTPerlScript>


The above will produce 15 in your web page.  Now, what's the point of
that?  Well, it is just an example. There's really no limit to what
can be done with Perl code.

You should also know that before the Perl code is processed, any
Movable Type tags contained within are processed *prior* to the Perl
code being evaluated. For example:

<MTPerlScript>
  print uc("<MTBlogName>");
</MTPerlScript>

This will uppercase your blog's name and return it. You can disable
this behavior by setting the 'preprocess' attribute to 0.

Additionally, once the Perl block has been processed, the output from it
can be scanned for Movable Type tags. Using the 'reprocess' attribute,
they will be processed before returning the output. For example:

<MTPerlScript reprocess="1">
  print "<M"."TBlogName>";
</MTPerlScript>

The above code will output your blog's name. Because the "MT" tag is
broken up that way, it is processed after the Perl code has been
evaluated.

So how about a somewhat more useful example?

<MTPerlScript>
  print localtime();
</MTPerlScript>

This will produce the current time (based on your server's clock).

Or how about (assuming you're using MySQL for storing your blogs):

<MTPerlScript>
  ($count) = $dbh->selectrow_array('select count(*) from mt_entry');
  print "entry count: $count";
</MTPerlScript>


Or define some routines you can use over and over:

<MTPerlScript package="mylib" once="1">
  sub hello {
    print "Hello, world!";
  }
</MTPerlScript>

<MTPerlScript>
  mylib::hello();
</MTPerlScript>


===========================================================================

"Safe" PerlScript

With version 2, PerlScript defaults to using a 'Safe' compartment
for executing code. This can be disabled by using the 'PerlScriptSafe'
configuration setting with a value of '0' (it defaults to '1').
This feature requires the 'Safe' CPAN module to be installed. Running
in safe mode will also not provide the '$dbh' database handle as described
in the above examples.

If safe mode is in use, you can also provide a list of the Perl routines
that may be used or excluded using the 'PerlScriptPermit' and
'PerlScriptDeny' configuration settings:

     PerlScriptPermit localtime,time

If 'PerlScriptPermit' is specified, ONLY those terms listed will be
allowed. If 'PerlScriptDeny' is given, ALL operators except those denied
are permitted. Please consult the documentation for the Safe Perl module
for more information.

These controls help reduce the risk of using this plugin for your MT
installation, but neither I (Brad Choate) or Six Apart, Ltd. can be
held responsible for any damages that may come from using this code.
It is intended for advanced users only.


===========================================================================

FOR MORE INFORMATION

  http://www.perldoc.com/


===========================================================================

LICENSE

Released under the MIT license. Please see
    http://www.opensource.org/licenses/mit-license.php
for details.


===========================================================================

SUPPORT

The latest version of this plugin can always be found in the Six Apart
subversion plugin repository, at this URL:

  http://code.sixapart.com/svn/mtplugins/PerlScript


Brad Choate
August 25, 2007


===========================================================================

CHANGELOG

2.0 - Updated for Movable Type 4.0. Simplified plugin features, so
please test if you are upgrading to make sure it behaves as expected.
Removed interface for Macros plugin. Added 'Safe' compartment mode
and configuration settings to govern it.

1.4 - Added 'reprocess' and 'preprocess' attributes to PerlScript tag.

1.3 - Added interface code for the Macros plugin-- sold separately :).

1.2 - MT tags produced by PerlScript will now be processed as advertised.

1.1 - Update to allow packages to only be evaluated once. This is useful
when you have PerlScript blocks that are processed in category, date or
individual archive pages.

1.0 - Initial release

