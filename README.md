# rubyrc — write your bashrc file in Ruby #
Every time you open a new terminal, Ruby will read your `rubyrc.rb` and translate it into bash.

# Installation #

```bash
cd
git clone https://github.com/ymasory/rubyrc.git
mv ~/.bashrc ~/.bashrc-before-rubryc
ln -s ~/rubyrc/bashrc.bash ~/.bashrc
```

# Customize #
Edit the provided `rubyrc.rb` to your liking.
This is where you put your former `.bashrc` customizations.

# Should I Use This? #
Probably not. I stopped using it after a year. Until it includes a way to write bash **functions** in Ruby, via some kind of parameter-passing scheme, it doesn't save you from as much bash agony as I'd hoped.
