const express = require('express');
const expressBunyanLogger = require('express-bunyan-logger');
const bodyParser = require('body-parser');

const logger = require('./logger');

const {
  register,
  setMuted,
  findUsersByTag,
  findUserById
} = require('./muter.js');

const port = 37405;
const app = express();

// app.use(expressBunyanLogger());
app.use(
  bodyParser.urlencoded({
    // to support URL-encoded bodies
    extended: true
  })
);

app.get('/', (req, res) => res.send('Hello World!'));

app.post('/connect', (req, res) => {
  const { tag } = req.body;

  if (!tag) {
    return res.sendStatus(400).send();
  }

  const utf8Tag = tag.split(' ');
  let sanatisedTag = '';

  utf8Tag.forEach(e => {
    sanatisedTag += String.fromCharCode(e);
  });

  const found = findUsersByTag(sanatisedTag);

  logger.info(
    `Connection request for user ${sanatisedTag}, found ${found.length} users`
  );

  if (found.length > 1) {
    res.status(200).json({
      // TODO: Clean up these status codes. Too many users.
      answer: 1
    });
  } else if (found.length < 1) {
    res.status(200).json({
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

app.post('/mute', async (req, res) => {
  const { id, mute } = req.body;

  if (!id || mute === undefined) {
    return res.sendStatus(400).send();
  }

  const muted = mute === 'true';

  const member = findUserById(id);

  if (member) {
    try {
      await setMuted({ user: member, muted });
    } catch (err) {
      logger.error(err);
      res.sendStatus(500).send();
    }
    res
      .json({
        success: true
      })
      .send();
  } else {
    res.sendStatus(404).send();
  }
});

app.listen(port, () => logger.info(`Listening on port ${port}`));
