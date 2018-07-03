
# Readme for OSX High Sierra


If you have problems installing vagrant etc. with home-brew on OS X High
sierra, it may be due to
[`csrutil` Apple system security policies](https://en.wikipedia.org/wiki/System_Integrity_Protection) 
preventing changes to parts of the file system, including `/usr/local` but _not files below it_.
You may have to either

  - uninstall and re-install home-brew  with                 
    `/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall)"`        
    `/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`          
  - fix permissions below `/usr/local` with `sudo chown -R $(whoami) $(brew --prefix)/*`          
  - install brew with `/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`          
  - or _reboot in recovery mode and execute_ `csrutil disable` which is not recommended)

/Thomas
