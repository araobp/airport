module.exports = {
  root: true,
  parserOptions: {
    ecmaVersion: 2021,
    sourceType: 'module'
  },
  extends: [
    'eslint:recommended',
    'plugin:svelte/recommended',
    'prettier'
  ],
  env: {
    browser: true,
    es2017: true
  },
  rules: {
    'svelte/no-inner-declarations': 'off'
  }
};