package MTPerlScript::Plugin;

use strict;

sub _hdlr_perl_script {
    my ($ctx, $args, $cond) = @_;

    my $preprocess = $args->{preprocess};
    my $reprocess = $args->{reprocess};

    my $out;
    if ((!defined $preprocess) || $preprocess) {
        # build out any child tags...
        defined($out = $ctx->slurp)
            or return $ctx->error($ctx->errstr);
    } else {
        $out = $ctx->stash('uncompiled');
    }

    my $code = qq{no strict; sub \{ my (\$ctx, \$args, \$dbh) = \@_; my \$this = \$ctx; local *stash = \$ctx->{__stash}; local *vars = \$ctx->{__stash}{vars}; local *args = \$args;} . $out . '}';

    # compile code
    my ($sub, $dbh);
    if (MT->config->PerlScriptSafe) {
        my $cpt = _get_perlscript_compartment();
        $sub = $cpt->reval($code);
    } else {
        # add database handle variable
        $dbh = MT::Object->driver->rw_handle;
        $sub = eval $code;
    }
    if (my $err = $@) {
        return $ctx->error("Error in PerlScript tag: $err");
    }

    # capture stdout, stderr to store to strings
    my $stdout = '';
    my $stderr = '';
    local *STDOUT;
    local *STDERR;

    tie *STDOUT, 'MTPerlScript::TiedOut', \$stdout;
    tie *STDERR, 'MTPerlScript::TiedOut', \$stderr;

    # the subroutine here is already bound to a compartmentalized
    # package, so just we're just using eval here to trap any
    # errors.
    {
        local $^W = 0;
        eval { $sub->($ctx, $args, $dbh) };
    }

    warn "Error executing PerlScript code: $@" if $@;
    warn "Error output from PerlScript tag: $stderr" if $stderr ne '';

    # restore stdout, stderr handles
    untie *STDOUT;
    untie *STDERR;

    # post-process if MT tags still exist:
    if ((!defined $reprocess) || $reprocess) {
        if ($stdout =~ m/<\$?MT.+?>/i) {
            my $builder = $ctx->stash('builder');
            my $tok = $builder->compile($ctx, $stdout, $cond);
            defined(my $out = $builder->build($ctx, $tok))
                or return $ctx->error($builder->errstr);
            $stdout = $out;
        }
    }

    return $stdout;
}

sub _get_perlscript_compartment {
    require MT::Request;
    my $r = MT::Request->instance;
    my $cfg = MT->config;

    my @mt_utils = qw(
        html_text_transform first_n_words dirify
        encode_html encode_js remove_html
        spam_protect encode_php encode_url decode_html encode_xml
    );

    my $cpt = $r->cache('perlscript_compartment');
    unless ($cpt) {
        require Safe;
        $cpt = new Safe;
        my $permit = $cfg->get('PerlScriptPermit');
        my $deny = $cfg->get('PerlScriptDeny');
        if (defined $permit) {
            my @permit = split /\s*,\s*/, $permit;
            push @permit, 'require'; # FIXME: For some reason, require is required
            $cpt->permit(@permit);
        }
        else {
            if (defined $deny) {
                my @deny = split /\s*,\s*/, $deny;
                $cpt->deny_only(@deny) if @deny;
            }
            $cpt->permit('require'); # FIXME: For some reason, require is required
        }
        # give access to the common MT::Util operations
        $cpt->share_from('MT::Util', \@mt_utils);
        $r->cache('perlscript_compartment', $cpt);
    }
    return $cpt;
}

package MTPerlScript::TiedOut;

use base qw( Tie::Handle );

sub TIEHANDLE {
    my ($class, $strref) = @_;
    bless {out=>$strref}, $class;
}

sub WRITE {
    my $self = shift;
    my ($buf, $len, $offset) = @_;
    ${$self->{out}} .= substr($buf, $offset, $len);
}

sub PRINT {
    my $self = shift;
    ${$self->{out}} .= join(($,||''), @_);
}

sub PRINTF {
    my $self = shift;
    my $fmt = shift;
    ${$self->{out}} .= sprintf($fmt, @_);
}

sub CLOSE {}

sub UNITE {}

sub DESTROY {}

1;
