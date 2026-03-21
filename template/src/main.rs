use anyhow::Result;
use clap::Parser;

/// {{description}}
#[derive(Parser)]
#[command(version, about)]
struct Cli {
    /// Name to greet
    #[arg(default_value = "{{project-name}}")]
    name: String,
}

fn main() -> Result<()> {
    env_logger::init();

    let cli = Cli::parse();
    {{crate_name}}::greet(&cli.name)?;

    Ok(())
}
