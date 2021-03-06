# Regit
*regit (rego, regere, rexi, rectum)* - it governs

A Discord bot that setups and fully moderates a Discord server based on a school. It handles authentication and total administration of the server and links it to all other school servers
running on the bot.

Servers created are private to school students (and verified guests from other schools who have very limited access).

Servers provide organized, specialized text and voice chat to allow academic cooperation and/or recreation for students. 

#### NOTE: *SERVERS MANAGED BY THIS BOT ARE TOTALLY UNDER THE CONTROL OF THE BOT AND CANNOT BE MANUALLY MODIFIED IN ANY WAY BY USERS (CHANGES ARE AUTOMATICALLY REVERTED)*

# Registration Process
One of either two ways can be followed:
1. User goes straight to website and authenticates with their Discord account
    1. User sets school email
    2. Confirmation email to prove
    3. Link between user and discord account
    4. They are shown invite link
    5. On server join, bot sets them up
2. User joins server
    0. Can only see #welcome 
    1. PM's website link and tells them to login with Discord account
    2. User sets school email on website
    3. Confirmation email to prove
    4. Link between user and discord account
    5. Bot sets everything up

# Web Component
The bot also runs a web server which allows all students/administrators/moderators to manage their presence on the server.

# School Server Layout

### ROLES
- **Guest** - Assigned to all students from other schools than the specific server's
- **Student** - Assigned to all *verified* students from the school for the server
- **Moderator** - Assigned to student-moderators on the specific server; moderators can delete/pin messages and add strikes to students who abuse the rules
- **Muted** - Assigned to students by moderators to prevent misbehaving students from sending any text-messages for an amount of time
- **Studying** - Assigned to students that are in *studymode* and therefore have all non-work related channels temporarily blocked

### TEXT-CHANNELS
- **#welcome** - Only channel new users can see, shows info on how to register.
- **#public-room** - All verified students and verified guests can talk here.
- **#guest-room** - Only verified guests can talk here.

*For Verified Students Only*
- **#announcements** - Global announcements for the school server that only the server owner (and bots) can post in.
- **#recreation** - General discussion of non-school related topics for all students in school. [GROUP]
- **#work** - General school discussion, homework help, etc for all students in school.
- **#freshmen | #sophomores | #juniors | #seniors** - Private chat for students in each grade.
- **#meta** - Discussion of the server itself for all students in school. [GROUP]
- **#{course_name}** - *Private text-channels for every course in the school based on teacher.*

### VOICE-CHANNELS
The voice channel system is unique to Discord. Instead of a static number of voice channels existing at all times, voice channels are dynamically
opened and closed based on users online, user requests, and when the existing number of voice channels are filled.
- **AFK** - Room for AFK students.
- **Music Room** - Room for a Music bot to play music chosen by users. Users must use push-to-talk here.
- **Public Room** - Opens when at least 1 verified guest is online; **ALL** (guest/verified/random) users can connect and speak.
- **Freshmen | Sophomores | Juniors | Seniors** - Private channels for each grade.
- **Room {Teacher Name}** - General room open to all students named randomly after a teacher.
- **{Game} Party** - Room dedicated to a game after majority of users connected start playing said game.
- **Study Room {Teacher Name}** - Room opened by a student in studymode, only for studying students.
- **[New Room]** - Symbolic empty room that transforms into a teacher room when someone joins. There is always 1 new room available.

### GROUPS
Groups are per-school server and allow for private text-channel and voice-channel chat for students with similar interests. Students decided what groups to join (there is no limit) and can
even create their own (limit in config file) and manage it themselves.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Apexal/regit. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

