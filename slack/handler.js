'use strict'

// const { InstallProvider } = require('@slack/oauth')

// const fetchSecret = require('./common/utils/fetchSecret')

// const installer = new InstallProvider({
//   clientId: fetchSecret('slack-client-id'),
//   clientSecret: fetchSecret('slack-client-secret'),
//   stateSecret: fetchSecret('slack-state-secret'),
// })

module.exports = async (event, context) => {
  const { path, query, method } = event
  const results = []
  const meta = { path, query, method }

  // const url = installer.generateInstallUrl({
  //   scopes: [
  //     'users.profile:write',
  //     'users.profile:read',
  //   ],
  // })

  return context
    .status(200)
    .succeed({
      status: 'ok',
      results,
      meta,
      // slack_url: url,
    })
}
