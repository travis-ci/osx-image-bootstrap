# osx-image-bootstrap

This repository contains the scripts and instructions for setting up an OS X VM
like the way the Travis CI OS X build environments are provisioned.

Please note that these instructions were written for the environment that Travis
CI runs OS X VMs in (currently vSphere), so you may have to tweak the steps
quite a bit if you're trying to set up a VM elsewhere.

## Creating a vanilla box

This should generally be re-done whenever a new "major" version of OS X comes
out (for example OS X 10.9 to OS X 10.10).

0. Create a new virtual machine in vSphere. 1 CPU, 4096 MB memory, 50 GiB disk
   space, attach the OS X install ISO from the datastore (current install ISO is
   10.9, we'll upgrade to 10.10 later).
0. Power on the VM, and open the console.
0. "Use English for the main language".
0. Open "Disk Utility" in the "Utilities" menu at the top of the screen.
0. Select the main disk (for me it's "53.69 VMware Virtual SATA Hard Drive
   Media") in the left sidebar, then select the "Erase" tab. Make sure the
   format is set to "Mac OS Extended (journaled)" and type "Macintosh HD" in the
   name ("Macintosh HD" is the standard name for the "main system disk" on most
   Macs). Click "Erase". This sets up the partition table and adds a partition
   to the disk. Close Disk Utility to go back to the installer.
0. Select "Continue" in the installer, then select the "Macintosh HD" disk you
   just created as the install disk.
0. Click "Install". Go have lunch (this step usually takes 20-30 minutes).
0. Select "United States" as the region.
0. Select "U.S." as the keyboard layout.
0. Select "Don't transfer any information now" in the "Transfer information to
   this Mac" dialogue.
0. Skip signing in with an Apple ID.
0. Accept the the OS X T&C / Software License Agreement.
0. Create an account with the following settings:
  - Full name: Travis CI
  - Account name: `travis`
  - Password: `travis`
  - Do _not_ require password to unlock screen
  - Uncheck "Set time zone based on current location"
  - Uncheck "Send Diagnostics & Usage data to Apple"
0. Select "UTC - United Kingdom" as the location.
0. Don't register the Mac.
0. Update to the latest version of OS X in the App Store.
0. Enable "Remote Login" in the Sharing Preference Pane. This enables SSH.
0. Run `xcode-select --install` and work through the dialog boxes that pop up
0. Disable automatic updates in the App Store preference pane
0. Disable every sleep option in the Energy Saver preference pane
0. Make sure automatic login is enabled in the Users and Groups preference pane
   (under Login Options).
0. Disable the Screen Saver
0. Check in Spotlight that indexing isn't running (wait until it's finished if
   it is).
0. Power off the VM and save this as a new "vanilla image".

## Creating a base box

0. Clone a vanilla image with the right version of OS X.
0. Download and install Xcode. Open it and download all the simulators.
0. Run `DevToolsSecurity -enable`.
0. Open the iOS simulator from Xcode → Open Developer Tools → iOS Simulator
0. Create a test project, build and run unit tests. Then delete the test project.
0. Run `bootstrap.sh` in this repository.
