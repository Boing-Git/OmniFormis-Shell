# 🤝 Contributing to Boing's Dotfiles

First off, thank you for considering contributing to my dotfiles! Your help in making this environment better and more performant is greatly appreciated.

## 🛠️ How to Contribute

1. **Fork the repository** to your own GitHub account.
2. **Clone the project** to your local machine.
3. **Create a branch** for your specific feature or fix (`git checkout -b feature/cool-new-script`).
4. **Commit your changes** (`git commit -m 'Add a cool new script'`).
5. **Push to your branch** (`git push origin feature/cool-new-script`).
6. **Open a Pull Request** against my `main` branch.

## 🎯 What I'm Looking For

* **Bug fixes** for the existing Hyprland (Lua) or Quickshell (QML) configurations.
* **Performance enhancements** for existing scripts and automation tools.
* *Note: Please avoid submitting entirely new color schemes or themes unless discussed and approved in an Issue first.*

## 📐 Helpful Guidelines

It would be incredibly helpful if you could try to follow these general guidelines when submitting code. Because this setup is highly modular, sticking to these patterns makes it much easier for me to maintain and update the modules down the road!

* **File Structure:** It helps a lot to keep things modular. If you are adding a feature to Hyprland or Quickshell, it's best to place it in its respective module folder (e.g., `hypr/modules/` or `quickshell/components/`) rather than combining it all into one large file.
* **Coding Style:** Try to match the existing indentation, formatting, and syntax conventions of the file you are editing.
* **Comments:** It's super helpful to include comments! Try to follow the same style of block comments or inline explanations found in the rest of the repository so things remain easy to read.
* **Theming Engine:** If your changes involve the UI, please try to hook them into the existing `Material 3 Expressive` dynamic theming engine instead of hardcoding colors. This ensures your additions switch themes seamlessly!

## 🐛 Found a Bug?

If you find a bug in the setup, please open an Issue first and include:
* Your OS version and environment details.
* The specific error message or unexpected behavior.
* Detailed steps to reproduce the issue.
