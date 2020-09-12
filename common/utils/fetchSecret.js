'use strict';

const { join } = require('path');
const fs = require('fs');

const SECRETS_PATH = '/var/openfaas/secrets';

module.exports = function fetchSecret (secretName) {
  return fs.readFileSync(join(SECRETS_PATH, secretName), 'utf8');
};
