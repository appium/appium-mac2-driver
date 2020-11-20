'use strict';

let gulp = require('gulp');
let boilerplate = require('appium-gulp-plugins').boilerplate.use(gulp);

boilerplate({
  build: 'appium-mac2-driver',
  coverage: {
    files: ['./test/unit/**/*-specs.js', '!./test/functional/**'],
    verbose: true
  }
});
