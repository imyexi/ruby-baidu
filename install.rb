gem_name = 'baidu'
path = File.expand_path('..',__FILE__)

puts "Installing gem #{gem_name}"
puts "Gem source path is #{path}"
puts `
cd #{path}
rm #{gem_name}-*.gem
echo '#{gem_name}-*.gem deleted'
gem build #{gem_name}.gemspec
gem uninstall #{gem_name} -x
gem install #{gem_name}-*.gem
`

puts 'Run Bundle'
puts `
cd #{path}
bundle
`