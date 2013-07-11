METRICS_FILES = FileList['lib/**/*.rb']

task :flog, [:all] do |t, args|
  flags = args.all ? "--all" : ""
  sh "flog -m #{flags} #{METRICS_FILES}"
end

task :flay do
  sh "flay #{METRICS_FILES}"
end
