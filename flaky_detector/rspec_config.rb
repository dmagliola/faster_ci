# Add to your RSpec configuration the setting to store test successes/failures in a file
# NOTE: if you change this path, you'll have to adapt `flaky_detector` to match
RSpec.configure do |config|
  config.example_status_persistence_file_path = "/tmp/rspec_examples.txt"
end
