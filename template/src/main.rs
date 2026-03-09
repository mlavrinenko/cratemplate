use anyhow::Result;

fn main() -> Result<()> {
    env_logger::init();

    {{crate_name}}::greet("{{project-name}}")?;

    Ok(())
}
