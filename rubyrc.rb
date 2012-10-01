###############################################################################
# bash resources, written in ruby
#
# the BashRC class translates it all to bash
###############################################################################

def home s
  "#{File.expand_path '~'}/#{s}"
end
$home_dir = home('')

require "#{$home_dir}/rubyrc/bashrc.rb"

if not ARGV.length == 1
  puts 'usage: ruby rubrc.rb [output_dest]'
  exit 1
end

$outpath = ARGV[0]

$hostname = `hostname`.strip
if `uname`.strip == 'Linux'
  $isLinux = true
  $isMac = false
else
  $isLinux = false
  $isMac = true
end

b = BashRC.new # this object does all the translating to bash

b.append_to_path '/sbin'

###############################################################################
# BASE PATHS
###############################################################################
b.declare 'home', $home_dir
b.declare 'desk', $desk
b.declare 'bin', $bin

###############################################################################
# DESKTOP
###############################################################################
#---- desktop ----#
open = if $isMac then 'open' else 'gnome-open' end
b.alias 'o', open

###############################################################################
# LANGUAGES AND FRAMEWORKS
###############################################################################
#---- scala ----#
b.append_to_path "#{$bin}/scala-2.9.2/bin"

def sbt (version, latest)
  xmx = case $hostname
          when 'types' then 6000
          when 'func.local' then 8000
          else 2000
        end
  xms = xmx
  xss = 100
  perm = 1024
  parts = version.split('.')
  name = if latest then parts[1] else parts[1..2].join end
  cmd = (
    "function sbt#{name} { " +
    "java -jar -Djava.awt.headless=true -Dfile.encoding=UTF8 " +
    "-Xmx#{xmx}M -Xms#{xms}M -Xss#{xss}M " +
    "-XX:+CMSClassUnloadingEnabled -XX:MaxPermSize=#{perm}M " +
    "-XX:-UseGCOverheadLimit #{$lib}/sbt/sbt-#{version}.jar \"$@\"; " +
    "}"
  )
  cmd
end
$extra_sbt_versions = ['0.7.7', '0.9.9', '0.10.1', '0.11.2', '0.11.3']
$latest_sbt_versions = ['0.12.0']
$all_sbt_versions = $latest_sbt_versions + $extra_sbt_versions
for versions, latest in [[$latest_sbt_versions, true], [$all_sbt_versions, false]] do
  for v in versions do
    b.add_raw sbt(v, latest)
  end
end

#---- android ----#
android_home = if $isLinux then "#{$bin}/android-sdk-linux"
               else "#{$bin}/android-sdk-macosx" end
b.export 'ANDROID_HOME', android_home
b.append_to_path "#{android_home}/platform-tools/"
b.append_to_path "#{android_home}/tools"
b.alias 'ai', 'mvn clean install android:deploy'

#---- java ----#
jdks = [
  '/usr/lib/jvm/java-6-openjdk',
  '/System/Library/Frameworks/JavaVM.framework/Versions/CurrentJDK/Home/'
]
for jdk in jdks do
  if File.exists? jdk
    ['JAVA_HOME', 'JDK_HOME', 'IDEA_JDK'].each { |varname|
      b.export varname, jdk
    }
    break
  end
end
b.prepend_to_path "#{$bin}/apache-maven-3.0.3/bin"
b.prepend_to_path "#{$bin}/apache-ant-1.8.3/bin"


###############################################################################
# UNIX
###############################################################################
#---- unix shortcuts ----#
b.alias '.s', "source #{home '.bashrc'}"
b.alias 'reboot', 'sudo reboot'
b.alias 'shutdown', 'sudo shutdown -h now'

#---- navigation ----#
b.alias '..', 'cd ..'
lscolor_params =
  if $isLinux then '--color="auto" --classify'
  elsif $isMac then '-G'
  else lscolor_params = ''
  end

# -h (human readable), -R (recursive), -A (all except . and ..),
# -S (sort by size), -c (sort by ctime), -t (sort by mtime),
# -u (sort by atime), -r (reverse sort)
# find . -type f -print0 | xargs -0 ls -l | sort -k5,5rn
# ls -al | sort -rn +4
b.alias 'ls', "ls #{lscolor_params}"
b.alias 'll', "ls #{lscolor_params} -lh"
b.alias 'la', "ls #{lscolor_params} -lhA"
b.alias 'lr', "ls #{lscolor_params} -lhR"
b.alias 'lk', "ls #{lscolor_params} -lhSr"
b.alias 'lc', "ls #{lscolor_params} -lhcr"
b.alias 'lu', "ls #{lscolor_params} -lhur"
b.alias 'lt', "ls #{lscolor_params} -lhtr"
b.alias 'c', 'clear'

###############################################################################
# SHELL
###############################################################################
#---- shell variabes ----#
b.export 'EDITOR', emacs_cmd
b.export 'HISTCONTROL', 'ignoreboth'


#---- shopt options (last, to not interfere with previous settings) ----#
shopt_set = [
  'cdable_vars', # if arg to 'cd' isn't a directory, assume it's a variable
  'cdspell', # minor spelling errors automatically corrected
  'checkwinsize', # update LINES and COLUMNS after every command
  'checkhash', # always check whether command in bash's hash actually exists
  'cmdhist', # attempts to save multipe-line commands as one history entry
  'histappend', # maintain history of commands session to session
  'interactive_comments', # '#' starts a comment
  'lithist', # along with 'cdmhist' option, uses newlines for multiline saving
  'no_empty_cmd_completion', # do not attempt completions on an empty line
  'progcomp', # completions on ??
  'promptvars' # prompt strings undergo variable and parameter expansion
]

shopt_unset = [
  'dotglob', # do not include hidden files in expansions
  'sourcepath' # 'source' command will not use PATH to find source file
]

shopt_set.each do |p|
  b.shopt_set p
end

shopt_unset.each do |p|
  b.shopt_unset p
end

###############################################################################
# FINALLY, WRITE THE BASHRC FILE
###############################################################################
b.write $outpath
