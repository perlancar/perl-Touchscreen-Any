package Touuchscreen::Any;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter::Rinci qw(import);
use File::Which qw(which);
use IPC::System::Options 'system', 'readpipe', -log=>1;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Common interface to touchscreen',
};

our %argopt_method = (
    method => {
        schema => 'str*',
    },
);

our %argopt_quiet = (
    quiet => {
        summary => "Don't output anything on command-line, ".
            "just return appropriate exit code",
        schema => 'true*',
        cmdline_aliases => {q=>{}, silent=>{}},
    },
);

sub _find_touchscreen_xinput_ids {
    my @ids;
    for my $line (split /^/m, `xinput`) {
        if (/(\w\S+?)\s+id=(\d+)/) {
            my ($name, $id) = ($1, $2);
            if ($name =~ /touch\s*screen/i) {
                log_trace "Found xinput touchscreen device: name=$name, id=$id";
                push @ids, $id;
            }
        }
    }
    @ids;
}

sub _disable_or_enable_touchscreen {
    my ($which, %args) = @_;

    my $method = $args{method};
    my $resmeta = {};

  METHOD_XINPUT: {
        last if $method && $method ne 'xinput';
        unless (which "xinput") {
            log_trace "xinput not in PATH, skipping xinput method";
            last;
        }
        $resmeta->{'func.method'} = 'xinput';
        my @ids = _find_touchscreen_xinput_ids()
            or return [412, "Cannot find any xinput touchscreen device"];
        system "xinput ".($which eq 'disable' ? 'disable' : 'enable')." $_" for @ids;
        $resmeta->{'func.device_ids'} = \@ids;
        [200, "OK", undef, $resmeta];
    }

    [412, "Cannot find any method to disable/enable touchscreen"];
}

$SPEC{disable_touchscreen} = {
    v => 1.1,
    summary => 'Disable touchscreen',
    args => {
        %argopt_method,
    },
};
sub disable_touchscreen {
    _disable_or_enable_touchscreen('disable', @_);
}

$SPEC{enable_touchscreen} = {
    v => 1.1,
    summary => 'Enable touchscreen',
    args => {
        %argopt_method,
    },
};
sub enable_touchscreen {
    _disable_or_enable_touchscreen('enable', @_);
}

$SPEC{touchscreen_is_enabled} = {
    v => 1.1,
    summary => 'Check whether touchscreen is enabled',
    args => {
        %argopt_quiet,
        %argopt_method,
    },
};
sub touchscreen_is_enabled {
    my ($which, %args) = @_;

    my $method = $args{method};
    my $resmeta = {};

  METHOD_XINPUT: {
        last if $method && $method ne 'xinput';
        unless (which "xinput") {
            log_trace "xinput not in PATH, skipping xinput method";
            last;
        }
        $resmeta->{'func.method'} = 'xinput';
        my @ids = _find_touchscreen_xinput_ids()
            or return [412, "Cannot find any xinput touchscreen device"];
        $resmeta->{'func.device_ids'} = \@ids;
        my $num_enabled = 0;
        for my $id (@ids) {
            my $output = readpipe("xinput list --long $id");
            if ($output =~ /This device is disabled/) {
            } else {
                $num_enabled++;
            }
        }
        my $enabled = $num_enabled == @ids ? 1:0;
        my $msg = $enabled ? "Touchscreen is enabled" :
            "Some/all touchscreens are NOT enabled";
        return [200, "OK", $enabled, {
            'cmdline.exit_code' => $enabled ? 0:1,
            'cmdline.result' => $args{quiet} ? '' : $msg,
            %$resmeta,
        }];
    } # METHOD_XINPUT

    [412, "Cannot find any method to check whether touchscreen is enabled"];
}

$SPEC{has_touchscreen} = {
    v => 1.1,
    summary => 'Check whether system has touchscreen device',
    args => {
        %argopt_quiet,
        %argopt_method,
    },
};
sub has_touchscreen {
    my ($which, %args) = @_;

    my $method = $args{method};
    my $resmeta = {};

  METHOD_XINPUT: {
        last if $method && $method ne 'xinput';
        unless (which "xinput") {
            log_trace "xinput not in PATH, skipping xinput method";
            last;
        }
        $resmeta->{'func.method'} = 'xinput';
        my @ids = _find_touchscreen_xinput_ids();
        $resmeta->{'func.device_ids'} = \@ids;
        my $msg = @ids ? "System has one or more touchscreens" :
            "System does NOT have any touchscreen";
        return [200, "OK", @ids ? 1:0, {
            'cmdline.exit_code' => @ids ? 0:1,
            'cmdline.result' => $args{quiet} ? '' : $msg,
            %$resmeta,
        }];
    } # METHOD_XINPUT

    [412, "Cannot find any method to disable/enable touchscreen"];
}

1;
# ABSTRACT:
