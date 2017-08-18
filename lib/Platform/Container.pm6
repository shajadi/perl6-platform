use v6;
use Text::Wrap;
use Platform::Emoji;
use Platform::Command;
use Platform::Util::OS;
use Terminal::ANSIColor;

class Platform::Container {

    has Str $.name is rw;
    has Str $.hostname is rw;
    has Str $.network = 'acme';
    has Bool $.network-exists = False;
    has Str $.domain = 'localhost';
    has Str $.dns;
    has Str $.data-path is rw;
    has Str $.projectdir;
    has Hash $.config-data;
    has %.last-result;
    has Str $.help-hint is rw;

    submethod TWEAK {
        $!data-path .= subst(/\~/, $*HOME);
        my $resolv-conf = $!data-path ~ '/resolv.conf';
        if $resolv-conf.IO.e {
            my $found = $resolv-conf.IO.slurp ~~ / nameserver \s+ $<ip-address> = [ \d+\.\d+\.\d+\.\d+ ] /;
            $!dns = $found ?? $/.hash<ip-address>.Str !! '';
        }
        my $proc = run <docker network inspect>, $!network, :out, :err;
        my $out = $proc.out.slurp-rest(:close);
        # $!network-exists = $out.Str.trim ne '[]';
    }

    method result-as-hash($proc) {
        my $out = ($proc ~~ Platform::Command) ?? $proc.out !! $proc.out.slurp-rest(:close);
        my $err = ($proc ~~ Platform::Command) ?? $proc.err !! $proc.err.slurp-rest;
        my %result =
            ret => $err.chars == 0,
            out => $out,
            err => $err
        ;
    }

    method last-command($proc?) {
        %.last-result = self.result-as-hash($proc) if $proc;
        self;
    }

    method as-string {
        my @lines;
        my Bool $success = %.last-result<err>.chars == 0;
        if $success {
            @lines.push: color('green') ~ "  : {$.projectdir.IO.relative}"; 
        } else {
            @lines.push: color('red') ~ "  : {$.projectdir.IO.relative}"; 

        }
        if %.last-result<err>.chars > 0 {
            my $wrapped-err = wrap-text(%.last-result<err>);
            my $sep = ($.help-hint && $.help-hint.chars > 0 
                )
                ?? '├' 
                !! '└';
            @lines.push: "  $sep─ " ~ join("\n  "~($.help-hint ?? "│" !! '')~"   ", $wrapped-err.lines) if %.last-result<err>;
            @lines.push: "  └─ " ~ color('yellow') ~ "hint: " ~ join("\n     ", wrap-text($.help-hint).lines) if $.help-hint;
        }
        @lines.join("\n");
    }

}
