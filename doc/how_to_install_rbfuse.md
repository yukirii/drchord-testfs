# How to install rbfuse

[github - flexfrank / rbfuse](https://github.com/flexfrank/rbfuse)


### 1. Create Gemfile
```
% cd ~/hoge/huga/testfs		# testfs_dir
% cat Gemfile
source "https://rubygems.org"

gem 'rbfuse', :github => 'flexfrank/rbfuse'
```

### 2. Install FUSE for OS X
[Home - FUSE for OS X](http://osxfuse.github.io/)

Download osxfuse-2.6.1.dmg and install it.

### 3. Create symbolic links
```
% cd /usr/local/include
% ls -la | grep osxfuse
drwxr-xr-x   4 root     wheel   136  7 19 05:53 osxfuse/

% ln -s osxfuse/fuse.h
% ln -s osxfuse/fuse		# It is directory
% ls -la | grep fuse
lrwxr-xr-x   1 shiftky  admin    12 10 22 23:03 fuse@ -> osxfuse/fuse
lrwxr-xr-x   1 shiftky  admin    14 10 22 23:02 fuse.h@ -> osxfuse/fuse.h
drwxr-xr-x   4 root     wheel   136  7 19 05:53 osxfuse/
```

### 4. Execute "bundle install"
```
% cd ~/hoge/huga/testfs		# testfs_dir
% bundle install
```