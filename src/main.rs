use carapace_spec_clap::Spec;
use clap::{value_parser, Arg, ArgAction, Command, ValueHint};
use clap_complete::{generate, Generator, Shell};
use std::io;

fn build_cli() -> Command {
    Command::new("ged")
        .arg(
            Arg::new("file")
                .help("some input file")
                .value_hint(ValueHint::AnyPath),
        )
        .arg(
            Arg::new("generator")
                .long("generate")
                .action(ArgAction::Set)
                .value_parser(value_parser!(Shell)),
        )
}

fn print_completions<G: Generator>(gen: G, cmd: &mut Command) {
    generate(gen, cmd, cmd.get_name().to_string(), &mut io::stdout());
}

fn main() {
    let matches = build_cli().get_matches();

    if let Some(generator) = matches.get_one::<Shell>("generator").copied() {
        let mut cmd = build_cli();
        eprintln!("Generating completion file for {generator}...");
        // print_completions(generator, &mut cmd);
        generate(Spec, &mut cmd, "example", &mut io::stdout());
    }
}
