use clap::{Parser, Subcommand};

mod bezier;
mod hypr;
mod keybinds;
mod qs;
mod theme;
mod utils;

#[derive(Parser)]
#[command(name = "omniformis", about = "Unified configuration CLI", version)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Manage themes
    Theme {
        #[command(subcommand)]
        cmd: ThemeCommands,
    },
    /// Quickshell management
    Qs {
        #[command(subcommand)]
        cmd: QsCommands,
    },
    /// Bezier preset management
    Bezier {
        #[command(subcommand)]
        cmd: BezierCommands,
    },
    /// Hyprland variables management
    Hypr {
        #[command(subcommand)]
        cmd: HyprCommands,
    },
    /// Kill Quickshell processes
    Kill,
    /// Launch Quickshell
    Launch {
        #[arg(short, long)]
        detached: bool,
    },
    /// Reload Quickshell
    Reload,
}

#[derive(Subcommand)]
enum HyprCommands {
    /// Get a hypr variable
    Get {
        key: String,
        /// Print the value as JSON
        #[arg(long)]
        json: bool,
    },
    /// Set a hypr variable (the value is validated against the variable's type)
    Set {
        key: String,
        #[arg(allow_hyphen_values = true)]
        value: String,
    },
    /// Flip a boolean hypr variable
    Toggle { key: String },
    /// List hypr variables
    List {
        /// Print machine-readable JSON instead of the table
        #[arg(long)]
        json: bool,
    },
    /// List every shortcut with its combination, the resolved keys and any clashes
    Binds {
        /// Print machine-readable JSON
        #[arg(long)]
        json: bool,
    },
}

#[derive(Subcommand)]
enum ThemeCommands {
    /// Generate theme from QML files
    Generate {
        light_file: String,
        dark_file: Option<String>,
    },
    /// List available themes
    List,
    /// Toggle between light and dark mode
    Toggle,
    /// Set a specific color scheme
    Set {
        name: String,
        mode: Option<String>,
    },
}

#[derive(Subcommand)]
enum QsCommands {
    /// Get a QS variable
    Get {
        key: String,
        /// Print the value as JSON
        #[arg(long)]
        json: bool,
    },
    /// Set a QS variable (the value is validated against the variable's type)
    Set {
        key: String,
        #[arg(allow_hyphen_values = true)]
        value: String,
    },
    /// Flip a boolean QS variable
    Toggle { key: String },
    /// List QS variables
    List {
        /// Print machine-readable JSON instead of "key: value" lines
        #[arg(long)]
        json: bool,
    },
    /// Kill Quickshell processes
    Kill,
    /// Start Quickshell
    Start {
        #[arg(short, long)]
        detached: bool,
    },
    /// Launch Quickshell
    Launch {
        #[arg(short, long)]
        detached: bool,
    },
    /// Reload Quickshell
    Reload,
}

#[derive(Subcommand)]
enum BezierCommands {
    /// Save current custom curves as a preset
    Save {
        name: String,
        #[arg(long)]
        payload: Option<String>,
    },
    /// Load a bezier preset
    Load { name: String },
    /// List available bezier presets
    List,
}

fn main() {
    let cli = Cli::parse();

    match cli.command {
        Commands::Theme { cmd } => match cmd {
            ThemeCommands::Generate {
                light_file,
                dark_file,
            } => theme::generate(&light_file, dark_file.as_deref()),
            ThemeCommands::List => theme::list(),
            ThemeCommands::Toggle => theme::toggle(),
            ThemeCommands::Set { name, mode } => theme::set(&name, mode.as_deref()),
        },
        Commands::Qs { cmd } => match cmd {
            QsCommands::Get { key, json } => qs::get(&key, json),
            QsCommands::Set { key, value } => qs::set(&key, &value),
            QsCommands::Toggle { key } => qs::toggle(&key),
            QsCommands::List { json } => qs::list(json),
            QsCommands::Kill => qs::kill(),
            QsCommands::Start { detached } => qs::launch(detached),
            QsCommands::Launch { detached } => qs::launch(detached),
            QsCommands::Reload => qs::reload(),
        },
        Commands::Bezier { cmd } => match cmd {
            BezierCommands::Save { name, payload } => bezier::save(&name, payload),
            BezierCommands::Load { name } => bezier::load(&name),
            BezierCommands::List => bezier::list(),
        },
        Commands::Hypr { cmd } => match cmd {
            HyprCommands::Get { key, json } => hypr::get(&key, json),
            HyprCommands::Set { key, value } => hypr::set(&key, &value),
            HyprCommands::Toggle { key } => hypr::toggle(&key),
            HyprCommands::List { json } => hypr::list(json),
            HyprCommands::Binds { json } => keybinds::list(json),
        },
        Commands::Kill => qs::kill(),
        Commands::Launch { detached } => qs::launch(detached),
        Commands::Reload => qs::reload(),
    }
}
