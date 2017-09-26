unit module Platform::CLI;

use Platform::CLI::Attach;
use Platform::CLI::Create;
use Platform::CLI::Destroy;
use Platform::CLI::Run;
use Platform::CLI::Remove;
#`(
use Platform::CLI::Rm;
use Platform::CLI::Run;
use Platform::CLI::SSH;
use Platform::CLI::SSL;
use Platform::CLI::Start;
use Platform::CLI::Stop;
)

our $data-path is export(:vars);

multi cli is export {
    OUTER::USAGE();
}

multi set-defaults(
    :D( :debug($debug) ),                                   #= Enable debug mode
    :a( :data-path($data-path) )    = '$HOME/.platform',    #= Location of resource files
    :d( :domain( $domain ) )        = 'localhost',          #= Domain address 
    :n( :network( $network ) )      = 'acme',               #= Network name
    ) is export {
    set-defaults(
        data-path   => $data-path,
        debug       => $debug,
        domain      => $domain,
        fallback    => 1,
        network     => $network,
        );
}

multi set-defaults(*@args, *%args) {
    for <data-path domain network> -> $class-var {
        for <
            Attach
            Create
            Destroy
            Run
            Remove
            > -> $module {
            my $class-name = "Platform::CLI::$module";
            if %args{$class-var}:exists {
                my $value = %args{$class-var};
                $value = $value.subst(/ '$HOME' /, $*HOME);
                ::($class-name)::("\$$class-var") = $value;
            }
        }
        %args«$class-var»:delete;
    }
    %args<fallback>:delete;
    %args<debug>:delete;
    %args;
}