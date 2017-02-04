# Example command module

module Regit
  module Commands
    module Imitate
      extend Discordrb::Commands::CommandContainer

      command(:imitate, min_args: 0, max_args: 1, description: 'Imitate you.', usage: '`!imitate`', permission_level: 1) do |event|
        #event.message.delete
        return if event.channel.private?

        target = event.user.on(event.server)

        quotes = Regit::Database::Quote.where(author_username: target.info.username)
        #return event.channel.send_temporary_message('You don\'t have enough quotes!', 5) if quotes.count < 5

        source = quotes.map { |m| m.text }.join('. ') + event.channel.history(100).select { |m| m.author == target }.map(&:content).join(". ")

        markov = MarkyMarkov::TemporaryDictionary.new
        markov.parse_string(source) 

        markov.generate_n_sentences(rand(5))
      end
    end
  end
end