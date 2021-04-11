# Detecting and Reporting Flaky Tests

These scripts will help you detect when flaky tests happen, and report them to your bug
tracker so you can fix them later.

Unfortunately, these scripts are not usable directly, you'll need to modify them for your
use case.

There are 3 files in this directory:

- `rspec_config.rb`: Example code showing how to configure RSpec to store the outcomes of 
    tests in a file. You won't add this file to your project, it's just a sample line that 
    you'll copy to your existing `spec_helper` file to configure RSpec.

- `flaky_detector`: Bash script that wraps your invocation of RSpec, retries failed tests,
    and detects flakies. For each flaky it finds, it'll call `flaky_reporter` to open a 
    ticket in your bug tracker. You'll copy this file onto your project, and will need to
    modify a couple of variables. Read the comments in the script for details of those 
    changes.

- `flaky_reporter`: An example script that gets called by `flaky_detector` for every file 
    that contains flaky  tests. It receives the path to the file that contains the flaky, 
    and the URL to your CI build to see more details. This script in its current form 
    **doesn't do anything**. You'll need to adapt it to actually talk to your bug tracker
    and create a ticket. It's just meant as an example of *what* you probably want to do, 
    but not how. 
  
    NOTE: I happen to have written it in Ruby, but this can be a Bash script, or whatever
    is easiest for your use case.



## Usage

Prepend the call to `flaky_detector` to your CI command that runs your tests.

For example:  
`./flaky_detector/flaky_detector bundle exec rspec  --format documentation`

If you are using the `split_tests` script from this repo:  
`./flaky_detector/flaky_detector bundle exec rspec $(./split_tests spec)`



## How does the flaky detection work / what is that crazy Bash command?

We detect flakies by retrying failed tests, and keeping RSpec's log of which tests 
succeeded or failed in each of the two runs. We then compare the two files looking for
tests that failed the first time, and succeeded when retried.

Below is a line-by-line explanantion of the crazy Bash command that does that:

```bash
# Find the failed lines from first run. 
# Result lines look like: ./spec/lib/something_spec.rb[1:5]  | failed | 0.0105 seconds  |
grep "| failed" $TEST_FAILURES_FILE_FIRST_RUN  

# Cuts the line at the first pipe, leaving the test definition. 
# Result lines look like: ./spec/lib/something_spec.rb[1:5]
| cut -d" " -f1
  
# Find the lines from the second run that correspond to the tests that failed in the first run.
# `grep -F` interprets the pattern as a list of fixed strings, separated by newlines, any of which is to be matched.    
| xargs -I{} grep -F {} $TEST_FAILURES_FILE

# We have the second run outcomes for the tests that failed on the first run. Find the successful ones.
# We have our flakies now.
| grep "| passed"
  
# Cuts the line at the first bracket, to leave only the filename.
# We do this because the test definition (the `[1:5]`) isn't really meaningful.  
# Result lines look like: ./spec/lib/something_spec.rb
| cut -d"[" -f1
  
# Only report each file once, if the same file has multiple flakies.
| uniq
  
# Call `flaky_reporter` once for each file containing flakies that we've found.  
| xargs -I{} $FLAKY_REPORTER_PATH --path "{}" --ci_build_url "$CI_BUILD_URL"
```
