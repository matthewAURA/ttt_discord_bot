const Discord = require('discord.js');
const config = require('./config.json');

const logger = require('./logger');

let guild;

const users = {};

const isMemberInVoiceChannel = member =>
  member.voiceChannelID === config.discord.channel;
const isMemberMutedByBot = member => users[member] === true;

const client = new Discord.Client();
client.login(config.discord.token);

client.on('ready', () => {
  guild = client.guilds.find('id', config.discord.guild);
});

client.on('voiceStateUpdate', (oldMember, newMember) => {
  // player leaves the ttt-channel
  if (
    oldMember.voiceChannel !== newMember.voiceChannel &&
    isMemberInVoiceChannel(oldMember)
  ) {
    if (isMemberMutedByBot(newMember) && newMember.serverMute)
      newMember.setMute(false).then(() => {
        users[newMember] = false;
      });
  }
});

function register(user) {
  users[user] = false;
}

async function setMuted({ user, muted }) {
  if (!isMemberInVoiceChannel(user)) {
    return Promise.resolve();
  }

  const reason = muted ? "You can't talk if you are dead" : '';

  logger.info(`Set muted state for user ${user} to ${muted}`);

  const result = await user.setMute(muted, reason);
  users[user] = muted;

  return result;
}

function findUsersByTag(tag) {
  return guild.members.filterArray(val =>
    val.user.tag.match(new RegExp(`.*${tag}.*`))
  );
}

function findUserById(id) {
  return guild.members.find('id', id);
}

module.exports = {
  register,
  setMuted,
  findUsersByTag,
  findUserById
};
