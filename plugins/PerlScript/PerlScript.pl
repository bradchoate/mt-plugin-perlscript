package MT::Plugin::PerlScript;

use strict;

use base qw( MT::Plugin );
use MT 4;

our $VERSION = '2.0';

MT->add_plugin({
    name => 'PerlScript',
    version => $VERSION,
    author_name => 'Brad Choate',
    author_link => 'http://bradchoate.com/',
    description => 'Provides a MT tag for executing Perl code from within your templates. This plugin is for advanced users who are familiar with coding in Perl.',
    registry => {
        tags => {
            block => {
                PerlScript => 'MTPerlScript::Plugin::_hdlr_perl_script',
            },
        },
        config_settings => {
            PerlScriptSafe => { default => 1 },
            PerlScriptPermitOps => undef,
            PerlScriptDenyOps => undef,
        },
    },
});

1;
