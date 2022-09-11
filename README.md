# ftw-cli

> **PLEASE NOTE:** This script is not supported by Check Point TAC or R&D. By using it you accept all the inherent risks and agree to hold the original author and Check Point Software Technologies, Ltd. blameless in all circumstances.

A set of tools for automating the First Time Configuration wizard on Check Point GAIA-based environments. 

Created by Michael Ibarra, Check Point Security Engineer, in July 2022. Feel free to reuse, modify, and distribute, but please retain credit to the original author specified herein. Enjoy!

# Overview
This script effectively replaces the web UI-based First Time Config Wizard, offering an interactive, CLI-based approach that can be run with merely a serial console session. This new-and-improved version supports management servers, MDS, standalone deployments, and of course, security gateways. Scalable platforms and VSX are not supported (yet!).

I've done my best to test every conceivable scenario, but there are a *lot* of combinations this script offers. Please report issues [here](https://github.com/crescentwire/ftw-cli/issues). I'm not a programmer or developer by trade or with any formal experience, so please be patient while I work through correcting any problems.

Best of luck, enjoy using it, and thank you for helping to make this better in advance!

# How to Use

1. Install GAIA using ISOmorphic or a bootable ISO on your physical or virtual hardware.
2. Connect via SSH or console to the system.
3. Copy the `ftw_cli_run.sh` file under some directory like `/home/admin`. 
   1. Alternatively, use `vi` to create a new, empty file and paste the contents of `ftw_cli_run.sh` inside. Then, save using `:wq!`.
4. Run `chmod +x ftw_cli_run.sh` to make the script executable.
5. Run the script using `./ftw_cli_run.sh`.
6. Follow the prompts!


# Reference

- [sk71000](https://supportcenter.checkpoint.com/supportcenter/portal?eventSubmit_doGoviewsolutiondetails=&solutionid=sk71000) - Overview of the First-Time Configuration Wizard
- [sk69701](https://supportcenter.checkpoint.com/supportcenter/portal?eventSubmit_doGoviewsolutiondetails=&solutionid=sk69701) - Overview of using `config_system`
- [GAIA R81 Administration Guide](https://sc1.checkpoint.com/documents/R81/WebAdminGuides/EN/CP_R81_Gaia_AdminGuide/Topics-GAG/Running-FTCW-in-CLI-Expert-Mode.htm) - Detailed use of `config_system`
