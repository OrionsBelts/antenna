'use strict'

/**
 * In order for this plugin to require correctly the following secrets must
 * be included in the stack definition of this function:
 * - 'auth0-domain'
 * - 'auth0-antenna-client-secret'
 * - 'auth0-antenna-audience'
 */
const authPlugin = require('./common/auth')

const schema = {
  response: {
    200: {
      type: 'object',
      properties: {
        hello: {
          type: 'string',
        },
      },
    },
  },
}

module.exports = async (fastify, options) => {
  fastify.register(authPlugin)

  fastify.route({
    path: '/',
    method: 'GET',
    schema,
    handler: function getHandler (request, reply) {
      // NOTE: `this` is bound to the fastify server
      reply.send({
        hello: 'world',
      })
    },
  })
}
