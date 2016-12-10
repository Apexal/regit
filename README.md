# Regit
*regit (rego, regere, rexi, rectum)* - he/she/it governs

A Discord bot that setups and fully moderates a Discord server based on a school. It handles authentication and total administration of the server and links it to all other school servers
running on the bot.

Servers created are private to school students (and verified guests from other schools who have very limited access).

Servers provide organized, specialized text and voice chat to allow academic cooperation and/or recreation for students. 

# Web Component
The bot also runs a web server which allows all students/administrators/moderators to manage their presence on the server.

# School Server Layout

### TEXT-CHANNELS
- **#welcome** - Only channel new users can see, shows info on how to register.
- **#public-room** - All verified students and verified guests can talk here.
- **#guest-room** - Only verified guests can talk here.

*For Verified Students Only*
- **#announcements** - Global announcements for the school server that only the server owner (and bots) can post in.
- **#recreation** - General discussion of non-school related topics for all students in school.
- **#work** - General school discussion, homework help, etc for all students in school.
- **#freshmen | #sophomores | #juniors | #seniors** - Private chat for students in each grade.
- **#meta** - Discussion of the server itself for all students in school.
- **#{course_name}** - *Private text-channels for every course in the school based on teacher.*

### VOICE-CHANNELS
The voice channel system is unique to Discord. Instead of a static number of voice channels existing at all times, voice channels are dynamically
opened and closed based on users online, user requests, and when the existing number of voice channels are filled.
- **AFK** - Room for AFK students.
- **Public Room** - Opens when at least 1 verified guest is online; **ALL** (guest/verified/random) users can connect and speak.
- **Freshmen | Sophomores | Juniors | Seniors** - Private channels for each grade that open when enough users in the respective grade is online.
- **Room {Teacher Name}** - General room open to all students named randomly after a teacher.
- **[New Room]** - Symbolic empty room that transforms into a teacher room when someone joins. There is always 1 new room available.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/regit. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

