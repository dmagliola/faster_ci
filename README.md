# faster_ci

This is a supplementary repo to my RailsConf 2021 talk 
["Speed up your test suite by throwing computers at it"](https://www.youtube.com/watch?v=T3TipTdx_2k)  

[![alt text](railsconf_youtube_thumbnail.png)](https://www.youtube.com/watch?v=T3TipTdx_2k)

Here you can find all the code examples mentioned in the talk, the slides deck, and some 
more resources.

Some of this code will require some modification for you to use, but i've documented this 
at the top of each file to try and make that easier.

I'm open to issues and PRs if you find improvements to make to these!

**Table of Contents**

- [Slides deck from the talk](#slides)
- [Splitting tests manually: Catch-all job](#splitting-tests-manually-catch-all-job)
- [Splitting tests automatically between boxes](#splitting-tests-automatically-between-boxes)
- [Inspecting the contents of Docker Images and Layers](#inspecting-the-contents-of-docker-images-and-layers)
- [Detecting and Reporting Flaky Tests](#detecting-and-reporting-flaky-tests)

## Slides

[Slides deck from the talk](Slides.pdf)  
[Slides including the full text from the talk](Slides_with_Script.pdf)


## Splitting tests manually: Catch-all job

When splitting your test suite into separate CI jobs based on the different test sub-directories
you have, it's better not to have a job for each specific directory. Instead, one job should
be a catch-all that runs "all tests except the ones the other jobs will"

That way, if you later add a new test sub-directory, you'll still run those tests in CI
if you forget to add a corresponding CI job.

The easiest way to do this is using `find` and `grep -v`:

```
# Instead of:
rspec spec/channels
rspec spec/controllers
rspec spec/helpers
rspec spec/integrations
rspec spec/mailers
rspec spec/models
rspec spec/system

# Do:
rspec spec/controllers
rspec spec/integrations
rspec spec/models
rspec spec/system
rspec $(find spec/**/* | grep -v "spec/controllers" | grep -v "spec/integrations" | grep -v "spec/models" | grep -v "spec/system")
```

This last job will run "everything else".

If you later add another job for a specific sub-directory, you should also add the exception
to this last "catchall" job, but now, if you forget, the cost is you run some tests twice
as opposed to forgetting to run some.


## Splitting tests automatically between boxes

**NOTE:** Before doing this, check whether your CI provider already has a better solution
for running tests in multiple machines in parallel. This is a fallback hack for those
providers that don't. In particular, if you are using CircleCI, their native solution is
**much** better than this, you should use that instead.

You can use the [`split_tests`](split_tests) script in this repo to help you split your 
test files between multiple boxes.

Copy the `split_tests` file somewhere into your project (you can use it as-is), and call
it passing in parameters to filter which tests you want to run in multiple boxes. These
are the same parameters you'd pass to `find` to find all the files to split.

You'll also need to define environment variables `BOX_COUNT`, with the total number of 
boxes to split between, and `BOX_INDEX` which specifies which of those boxes you're 
running on at the moment, as a 0-based number. In your CI environment you can do this
by abusing their "Build Matrix" feature as explained in the talk.

Example CI commands:

- Run all tests in the `spec` directory:   
  `rspec $(./split_tests spec)`
- Run tests files that match a specific pattern, inside `spec/some_dir`:    
  `rspec $(./split_tests spec/some_dir -name "*_spec.rb")`


## Inspecting the contents of Docker Images and Layers

Use [the dive tool](https://github.com/wagoodman/dive)!

Follow the installation and usage instructions in that repo to get it started.

To optimize your layers, focus on layers that take a significant amount of space, `Tab`
to explore the filesystem, filter out "unmodified" files with `Ctrl+U`, and browse around
to see if any large files/directories look deletable.

If you find some, you can delete them by adding `rm` commands to your Dockerfile:

```
RUN command_that_leaves_behind_useless_files \
    && rm -rf useless_path_you_found_with_dive
```

Make sure to do the deletion in the same Docker step using `&&`, or the deletion will
happen in a separate layer, and the files you are deleting will *still* be there where you
found them.


## Detecting and Reporting Flaky Tests

Find sample scripts ready to be adapted to your needs, and documentation on how they work 
and how to use them in the [flaky_detector directory](flaky_detector)