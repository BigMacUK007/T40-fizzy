require "rake/testtask"

namespace :test do
  task :prepare_saas => :environment do
    $LOAD_PATH.unshift Fizzy::Saas::Engine.root.join("test").to_s
    require "test_helper"
  end

  desc "Run tests for fizzy-saas gem"
  Rake::TestTask.new(:saas => :prepare_saas) do |t|
    t.libs << "test"
    t.test_files = FileList[Fizzy::Saas::Engine.root.join("test/**/*_test.rb")]
    t.warning = false
  end
end
