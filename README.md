# ftw-cli

> **PLEASE NOTE:** This script is not supported by Check Point TAC or R&D. By using it you accept all the inherent risks and agree to hold the original author and Check Point Software Technologies, Ltd. blameless in all circumstances.

A set of tools for automating the first time configuration wizard on Check Point GAIA-based environments. 

Created by Michael Ibarra, Check Point Security Engineer, in July 2022. Feel free to reuse, modify, and distribute, but please retain credit to the original author specified herein. Enjoy!


# How to Use
This script can be run on a physical or virtual Check Point appliance, configured as a gateway. (Management is possible, but is outside the scope of this script for now.)

1. Install GAIA using ISOmorphic or using a bootable ISO on your physical or virtual hardware.
2. Connect via SSH or console to the system.
3. Copy or use `vi` to place the `ftw_cli_run.sh` file under some directory like `/home/admin`.
4. Run `chmod +x ftw_cli_run.sh` to make the script executable.
5. Run the script using `./ftw_cli_run.sh`.
6. Follow the prompts!


# Reference

- [sk71000](https://supportcenter.checkpoint.com/supportcenter/portal?eventSubmit_doGoviewsolutiondetails=&solutionid=sk71000) - Overview of the First-Time Configuration Wizard
- [sk69701](https://supportcenter.checkpoint.com/supportcenter/portal?eventSubmit_doGoviewsolutiondetails=&solutionid=sk69701) - Overview of using `config_system`
- [GAIA R81 Administration Guide](https://sc1.checkpoint.com/documents/R81/WebAdminGuides/EN/CP_R81_Gaia_AdminGuide/Topics-GAG/Running-FTCW-in-CLI-Expert-Mode.htm) - Detailed use of `config_system`
