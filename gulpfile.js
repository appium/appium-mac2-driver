'use strict';

let gulp = require('gulp');
let boilerplate = require('@appium/gulp-plugins').boilerplate.use(gulp);

boilerplate({
  build: 'appium-mac2-driver',
  files: ['index.js', 'lib/**/*.js', 'test/**/*.js', '!gulpfile.js'],
  coverage: {
    files: ['./test/unit/**/*-specs.js', '!./test/functional/**'],
    verbose: true
  }
});
