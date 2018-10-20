const express = require('express');
const logger = require('./logger');

const {
  register,
  setMuted,
  findUsersByTag,
  findUserById
} = require('./muter.js');

const port = 37405;
const app = express();

app.get('/', (req, res) => res.send('Hello World!'));

app.get('/connect', (req, res) => {
  const utf8Tag = req.params.tag.split(' ');
  let tag = '';

  utf8Tag.forEach(e => {
    tag += String.fromCharCode(e);
  });

  const found = findUsersByTag(utf8Tag);

  logger.info(
    `Connection request for user ${tag}, found ${found.length} users`
  );

  if (found.length > 1) {
    res.status(400).json({
      // TODO: Clean up these status codes. Too many users.
      answer: 1
    });
  } else if (found.length < 1) {
    res.status(400).json({
      answer: 0 // no found
    });
  } else {
    register(found[0]);
    res.json({
      tag: found[0].user.tag,
      id: found[0].id
    });
  }
});

app.get('/mute', async (req, res) => {
  const { id } = req.params;
  const { mute } = req.params;

  if (typeof id !== 'string' || typeof mute !== 'boolean') {
    return res.statusCode(400).send();
  }

  const member = findUserById(id);

  if (member) {
    await setMuted({ user: member, muted: true });
    res
      .json({
        success: true
      })
      .send();
  } else {
    res.statusCode(404).send();
  }
});

app.listen(port, () => logger.info(`Listening on port ${port}`));
