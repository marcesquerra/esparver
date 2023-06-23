use carapace_spec_clap::Spec;
use clap::builder::PossibleValue;
use clap::ValueEnum;
use clap::{value_parser, Arg, ArgAction, Command, ValueHint};
use clap_complete::{generate, Generator, Shell};
use std::fmt::Display;
use std::io;

/// Shell with auto-generated completion script available.
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
#[non_exhaustive]
pub enum Target {
    AShell(Shell),
    Carapace,
}

impl Display for Target {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        self.to_possible_value()
            .expect("no values are skipped")
            .get_name()
            .fmt(f)
    }
}

fn build_cli() -> Command {
    Command::new("ged")
        .arg(
            Arg::new("file")
                .help("some input file")
                .value_hint(ValueHint::AnyPath),
        )
        .arg(
            Arg::new("generator")
                .help("generate code complation")
                .long("generate")
                .action(ArgAction::Set)
                .value_parser(value_parser!(Target)),
        )
}

// Hand-rolled so it can work even when `derive` feature is disabled
impl ValueEnum for Target {
    fn value_variants<'a>() -> &'a [Self] {
        &[
            Target::AShell(Shell::Bash),
            Target::AShell(Shell::Elvish),
            Target::AShell(Shell::Fish),
            Target::AShell(Shell::PowerShell),
            Target::AShell(Shell::Zsh),
            Target::Carapace,
        ]
    }

    fn to_possible_value<'a>(&self) -> Option<PossibleValue> {
        match self {
            Target::AShell(a_shell) => a_shell.to_possible_value(),
            Target::Carapace => Some(PossibleValue::new("carapace")),
        }
    }
}

fn print_completions(target: Target, cmd: &mut Command) {
    match target {
        Target::AShell(gen) => generate(gen, cmd, cmd.get_name().to_string(), &mut io::stdout()),
        Target::Carapace => generate(Spec, cmd, cmd.get_name().to_string(), &mut io::stdout()),
    }
}

fn main() {
    let matches = build_cli().get_matches();

    if let Some(target) = matches.get_one::<Target>("generator").copied() {
        let mut cmd = build_cli();
        eprintln!("Generating completion file for {target}...");
        print_completions(target, &mut cmd);
    }
}
