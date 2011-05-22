if (node[:environment][:name].include?("staging"))
  run "echo Syncing public dir with S3:"
  run "cd config; ln -sf assets-#{node[:environment][:name]}.yml assets.yml"
  run "bundle exec jammit-s3 "
end
