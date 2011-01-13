# Optional publish task for Rake

begin
  require 'rake/contrib/sshpublisher'
  require 'rake/contrib/rubyforgepublisher'

  publisher = Rake::CompositePublisher.new
  publisher.add Rake::RubyForgePublisher.new('rake', 'jimweirich')
  publisher.add Rake::SshFilePublisher.new(
    'umlcoop',
    'htdocs/software/rake',
    '.',
    'rake.blurb')

  desc "Publish the Documentation to RubyForge."
  task :publish => [:rdoc] do
    publisher.upload
  end
rescue LoadError => ex
  puts "#{ex.message} (#{ex.class})"
  puts "No Publisher Task Available"
end
