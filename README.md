A [Hubot](https://hubot.github.com/) script to open / close ports on security groups automatically in AWS based on a user's presence.

If you regularly open ports in security groups in AWS to your current IP, this is the tool for you.  When Hubot sees you sign in, it will send you a picture.  When it's loaded in your chat client (if you're using Adium, you'll need to install the [Adinline](http://www.adiumxtras.com/index.php?a=xtras&xtra_id=7926) plugin) Hubot is able to get your IP, and then open the security group(s) to you.

# Installation
Assuming you've installed [Hubot](https://hubot.github.com/) and have an instance already running, the steps are simple.  Just add "hubot-aws-sesame" to both your dependencies list in Hubot's package.json file as well as the external-scripts.json file.  Then run:

```bash
npm install
```

# Configuration:

* HUBOT_AWS_REGION
* HUBOT_AWS_KEY_ID
* HUBOT_AWS_SECRET_KEY
* HUBOT_AWS_SEC_RULES
* HUBOT_ROOT_URL

```HUBOT_AWS_SEC_RULES``` should be of the form (spaces are ignored):

<code>
  &lt;sec group id&gt;: &lt;port start&gt;[ - &lt;port end&gt;][, &lt;port start&gt; - &lt;port end&gt;];
</code>

For instance, each of the following would work:

* sg-123: 22
* sg-123: 20 - 222
* sg-123: 22; sg-456: 1-1600
* sg-123: 10 - 20; sg-456: 30

HUBOT_ROOT_URL should be the root URL of an internet visible host.  This is necessary so that a message can be sent to the client containing a link to this bot's Hubot web server.  For instance, the following are valid values:

* http://12.34.56.78
* https://bothost.example.com
* http://12.34.56.78:123

# Commands:

    hubot show firewall - Show all users who currently have access to AWS
