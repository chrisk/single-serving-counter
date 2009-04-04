require 'erb'

set :application, "single-serving-counter.com"
set :user, "chrisk"

set :repository, "git://github.com/#{user}/#{application}.git"
set :deploy_to, "/home/#{user}/#{application}"

set :scm, :git
set :branch, "master"
set :deploy_via, :remote_cache

default_run_options[:pty] = true
ssh_options[:port] = 24832


role :app, application
role :web, application
role :db,  application, :primary => true

after "deploy:update_code", "deploy:copy_apache_config"
after "deploy:setup", "deploy:install_apache_config"

namespace :deploy do
  desc "Finalize without Rails-specific commands"
  task :finalize_update, :except => { :no_release => true } do
    run "chmod -R g+w #{release_path}" if fetch(:group_writable, true)
  end

  desc "Update the apache vhost config"
  task :copy_apache_config do
    template_path = File.join(File.dirname(__FILE__), "apache_vhost.conf.erb")
    conf = ERB.new(File.read(template_path), nil, '-').result(binding)
    put conf, "#{shared_path}/system/apache_vhost.conf"
    sudo "cp #{shared_path}/system/apache_vhost.conf /etc/apache2/sites-available/#{application}"
    run "rm #{shared_path}/system/apache_vhost.conf"
  end

  desc "Gracefully restart apache"
  task :restart do
    sudo "/usr/sbin/apache2ctl graceful"
  end

  desc "Install the apache vhost config"
  task :install_apache_config do
    copy_apache_config
    sudo "/usr/sbin/a2ensite #{application}"
    sudo "/etc/init.d/apache2 reload"
  end

  desc "Remove the apache vhost config"
  task :remove_apache_config do
    copy_apache_config
    sudo "/usr/sbin/a2dissite #{application}"
    sudo "/etc/init.d/apache2 reload"
  end
end