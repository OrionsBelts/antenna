'use strict'

const fetchSecret = require('./common/utils/fetchSecret')

module.exports = async (event, context) => {
  try {
    const SOME_SECRET = fetchSecret('SOME_SECRET')

    const result = {
      event,
      status: `Received input: ${JSON.stringify(event.body)}`,
      data: `successfully read ${SOME_SECRET}`,
    }

    return context.status(200).succeed(result)
  } catch (e) {
    return context.status(500).fail(e)
  }
}
