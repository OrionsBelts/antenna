// Copyright (c) Alex Ellis 2017. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.

'use strict'

const fastify = require('fastify')

// - require handler
const handler = require('./function/handler')

// - applcation setup
const app = fastify({
  logger: true,
})

// - register plugins
app.register(handler)

// - start application
const start = async () => {
  try {
    const port = process.env.http_port || 3000
    const address = await app.listen(port)
    app.log.info(`OpenFaaS Node.js listening on: ${address}`)
  } catch (err) {
    app.log.error(err)
    process.exit(1)
  }
}

start()
