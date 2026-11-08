// src: blume.config.ts
// @(#) : blume basic settings
//
// Copyright (c) 2026- atsushifx <http://github.com/atsushifx>
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import { defineConfig } from 'blume';

export default defineConfig({
  title: 'deckrd',
  description: 'Goals to Requirements, Specifications, Implementation, and Tasks.',
  deployment: {
    site: 'https://aglabo.github.io/deckrd',
    base: '/deckrd',
  },
  i18n: {
    defaultLocale: 'en',
    locales: [
      { code: 'en', label: 'English' },
      { code: 'ja', label: '日本語' },
    ],
  },
});
