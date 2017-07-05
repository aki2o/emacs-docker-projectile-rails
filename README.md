# What's this?

This is a extension of Emacs that let projectile-rails work under docker container.  
You'll be able to develop using projectile-rails when rails run under docker container.

# Install

### If use package.el

2017/07/05 Not yet regist.  

### If use el-get.el

2017/07/05 Not yet regist.  

### If use auto-install.el

```lisp
(auto-install-from-url "https://raw.github.com/aki2o/emacs-docker-projectile-rails/master/docker-projectile-rails.el")
```
-   In this case, you need to install each of the following dependency.

### Manually

Download docker-projectile-rails.el and put it on your load-path.  
-   In this case, you need to install each of the following dependency.

### Dependency

-   [projectile-rails.el](https://github.com/asok/projectile-rails)
-   [docker.el](https://github.com/Silex/docker.el)

# Configuration

```lisp
(require 'docker-projectile-rails)
(docker-projectile-rails:activate)
```

# Usage

You do not need anthing else using robe.  
docker-projectile-rails.el appends the following few steps into `projectile-rails-generate`.  
1.  select container
    -   select the docker container names which product code run in.

### Reconfigure

The above steps will be cached.  
You'll be able to rerun it by M-x `docker-projectile-rails:configure-current-project`.



**Enjoy!!!**
