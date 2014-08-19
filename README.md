Hubot script to open / close ports on security groups automatically in AWS based on a user's presence


# Configuration:

   HUBOT_AWS_REGION
   HUBOT_AWS_KEY_ID
   HUBOT_AWS_SECRET_KEY
   HUBOT_AWS_SEC_RULES
   HUBOT_ROOT_URL

# Commands:

   hubot show firewall - Show all users who currently have access to AWS

# Notes:

   HUBOT_AWS_SEC_RULES should be of the form (spaces are ignored):
   <sec group id>: <port start>[ - <port end>][, <port start> - <port end>];

   For instance, each of the following would work:
   sg-123: 22
   sg-123: 20 - 222
   sg-123: 22; sg-456: 1-1600
   sg-123: 10 - 20; sg-456: 30

   HUBOT_ROOT_URL should be the root URL of an internet visible host.  This
   is necessary so that a message can be sent to the client containing a link
   to this bot's Hubot web server.

   For instance, the following are valid values:
   http://12.34.56.78
   https://bothost.example.com
   http://12.34.56.78:123
 
