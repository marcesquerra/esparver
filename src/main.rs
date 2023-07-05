mod nickelodeon;

use carapace_spec_clap::Spec;
use clap::builder::PossibleValue;
use clap::{
    crate_version, value_parser, Arg, ArgAction, Args, Command, Parser, Subcommand, ValueHint,
};
use clap::{CommandFactory, ValueEnum};
use clap_complete::{generate, Generator, Shell};
use nickel_lang::deserialize;
use nickel_lang::eval::cache::CacheImpl;
use nickel_lang::program::Program;
use nickel_lang::term::RichTerm;
use serde::Deserialize;
use serde::Serialize;
use std::fmt::Display;
use std::io;
use std::path::PathBuf;

use crate::nickelodeon::load_configuration;

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

/// Here's my app!
#[derive(Debug, Parser)]
#[clap(name = "ged", version)]
#[command(arg_required_else_help = true)]
pub struct Arguments {
    /// Sets a custom config file
    #[arg(short, long, value_name = "FILE", global = true)]
    config: Option<PathBuf>,

    // #[clap(flatten)]
    // global_opts: GlobalOpts,
    #[clap(subcommand)]
    command: GedCommand,
}

#[derive(Debug, Subcommand)]
enum GedCommand {
    /// Help message for read.
    #[clap(hide = true)]
    GenCompleter {
        completer: Target,
    },
    ShowConfiguration,
}

fn print_completions(target: Target, cmd: &mut Command) {
    match target {
        Target::AShell(gen) => generate(gen, cmd, cmd.get_name().to_string(), &mut io::stdout()),
        Target::Carapace => generate(Spec, cmd, cmd.get_name().to_string(), &mut io::stdout()),
    }
}

#[derive(Serialize, Deserialize, Debug, Default)]
struct Configuration {
    pub foo: String,
}

fn main() {
    let args = Arguments::parse();
    let mut cmd: Command = Arguments::command_for_update();

    let configuration = load_configuration::<Configuration>("esparver", args.config); //Configuration::deserialize(rt);

    match args.command {
        GedCommand::GenCompleter { completer } => print_completions(completer, &mut cmd),
        GedCommand::ShowConfiguration => println!("{:?}", configuration),
    };
}
