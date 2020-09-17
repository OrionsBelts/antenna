'use strict'

module.exports = async (event, context) => {
  const { path, query, method } = event
  const results = []
  const meta = { path, query, method }

  return context
    .status(200)
    .succeed({
      status: 'ok',
      results,
      meta,
    })
}
